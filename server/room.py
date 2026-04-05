from __future__ import annotations
import asyncio
from enum import IntEnum

from session import Session
from protocol import (
    serialize_card, deserialize_card, serialize_hand,
    serialize_giruda, deserialize_giruda, deserialize_hand,
    error_msg,
)
from game.game_options import GameOptions
from game.round_manager import RoundManager, Phase
from game.bidding_state import Giruda
from game.declarer_phase import FriendCallType
from game.deal_miss_penalty import DealMissPenalty


class RoomState(IntEnum):
    LOBBY = 0
    IN_GAME = 1
    BETWEEN_ROUNDS = 2


TURN_TIMEOUT = 60.0


class Room:
    def __init__(self, code: str, host: Session) -> None:
        self.code = code
        self.host_session_id = host.session_id
        self.seats: list[Session | None] = [None] * 5
        self.options = GameOptions()
        self.state = RoomState.LOBBY
        self.round_manager: RoundManager | None = None
        self.deal_miss_penalty: DealMissPenalty | None = None
        self.dealer_index = 0
        self.cumulative_scores = [0] * 5
        self._turn_timer: asyncio.Task | None = None

        self._add_player(host)

    def _add_player(self, session: Session) -> int | None:
        for i in range(5):
            if self.seats[i] is None:
                self.seats[i] = session
                session.room_code = self.code
                session.seat_index = i
                return i
        return None

    def remove_player(self, session: Session) -> None:
        if session.seat_index is not None and self.seats[session.seat_index] is session:
            self.seats[session.seat_index] = None
        session.room_code = None
        session.seat_index = None
        if session.session_id == self.host_session_id:
            self._migrate_host()

    def _migrate_host(self) -> None:
        for s in self.seats:
            if s is not None and s.connected:
                self.host_session_id = s.session_id
                return

    def player_count(self) -> int:
        return sum(1 for s in self.seats if s is not None)

    def is_empty(self) -> bool:
        return all(s is None for s in self.seats)

    def _get_players_info(self) -> list:
        result = []
        for i in range(5):
            s = self.seats[i]
            if s is None:
                result.append(None)
            else:
                result.append({
                    "seat": i,
                    "name": s.player_name,
                    "is_host": s.session_id == self.host_session_id,
                    "connected": s.connected,
                })
        return result

    # --- Message handling ---

    async def handle_message(self, session: Session, msg: dict) -> None:
        msg_type = msg.get("type", "")

        if self.state == RoomState.LOBBY:
            await self._handle_lobby(session, msg_type, msg)
        elif self.state == RoomState.IN_GAME:
            await self._handle_in_game(session, msg_type, msg)
        elif self.state == RoomState.BETWEEN_ROUNDS:
            await self._handle_between_rounds(session, msg_type, msg)

    # --- Lobby ---

    async def _handle_lobby(self, session: Session, msg_type: str, msg: dict) -> None:
        if msg_type == "set_options":
            if session.session_id != self.host_session_id:
                await session.send(error_msg("NOT_HOST", "Only the host can change options"))
                return
            self._apply_options(msg.get("options", {}))
            await self._broadcast({"type": "options_updated", "options": msg.get("options", {})})

        elif msg_type == "start_game":
            if session.session_id != self.host_session_id:
                await session.send(error_msg("NOT_HOST", "Only the host can start the game"))
                return
            if self.player_count() < 5:
                await session.send(error_msg("NOT_ENOUGH_PLAYERS", "Need 5 players to start"))
                return
            await self._start_round()

        elif msg_type == "kick_player":
            if session.session_id != self.host_session_id:
                await session.send(error_msg("NOT_HOST", "Only the host can kick players"))
                return
            seat = msg.get("seat", -1)
            if 0 <= seat < 5 and self.seats[seat] is not None:
                kicked = self.seats[seat]
                if kicked.session_id == self.host_session_id:
                    return
                self.remove_player(kicked)
                await kicked.send({"type": "kicked"})
                await self._broadcast({"type": "player_left", "seat": seat, "name": kicked.player_name, "reason": "kicked"})

    # --- In Game ---

    async def _handle_in_game(self, session: Session, msg_type: str, msg: dict) -> None:
        rm = self.round_manager
        seat = session.seat_index

        if rm.phase == Phase.BIDDING:
            await self._handle_bidding(session, seat, msg_type, msg)
        elif rm.phase == Phase.DECLARER:
            await self._handle_declarer(session, seat, msg_type, msg)
        elif rm.phase == Phase.PLAY:
            await self._handle_play(session, seat, msg_type, msg)

    async def _handle_bidding(self, session: Session, seat: int, msg_type: str, msg: dict) -> None:
        bm = self.round_manager.bidding_manager

        if msg_type == "bid":
            if seat != bm.current_turn:
                await session.send(error_msg("NOT_YOUR_TURN", "It is not your turn"))
                return
            count = msg.get("count", 0)
            giruda = deserialize_giruda(msg.get("giruda", "none"))
            if not bm.place_bid(seat, count, giruda):
                await session.send(error_msg("INVALID_BID", "Invalid bid"))
                return
            self._cancel_turn_timer()
            await self._broadcast({
                "type": "bid_placed", "seat": seat,
                "count": count, "giruda": msg.get("giruda"),
            })
            await self._check_bidding_end()

        elif msg_type == "pass":
            if seat != bm.current_turn:
                await session.send(error_msg("NOT_YOUR_TURN", "It is not your turn"))
                return
            if not bm.pass_turn(seat):
                await session.send(error_msg("INVALID_ACTION", "Cannot pass"))
                return
            self._cancel_turn_timer()
            await self._broadcast({"type": "bid_passed", "seat": seat})
            await self._check_bidding_end()

        elif msg_type == "deal_miss":
            if seat != bm.current_turn:
                await session.send(error_msg("NOT_YOUR_TURN", "It is not your turn"))
                return
            if not bm.declare_deal_miss(seat):
                await session.send(error_msg("INVALID_ACTION", "Cannot declare deal miss"))
                return
            self._cancel_turn_timer()
            penalty = self.deal_miss_penalty.calculate_penalty(self.dealer_index)
            self.deal_miss_penalty.record_deal_miss(self.dealer_index)
            self.cumulative_scores[seat] -= penalty
            self.dealer_index = self.deal_miss_penalty.next_dealer_after_deal_miss(
                self.dealer_index, seat
            )
            await self._broadcast({
                "type": "deal_miss_declared", "seat": seat,
                "penalty": penalty, "pot": self.deal_miss_penalty.pot,
                "scores": list(self.cumulative_scores),
            })
            await self._start_round()

    async def _check_bidding_end(self) -> None:
        bm = self.round_manager.bidding_manager
        if bm.is_finished():
            self.round_manager.advance_from_bidding()
            di = self.round_manager.declarer_index
            bid = self.round_manager.bid
            giruda = self.round_manager.giruda

            declarer_session = self.seats[di]
            await declarer_session.send({
                "type": "declarer_phase_start",
                "hand": serialize_hand(self.round_manager.declarer_phase.hand),
                "kitty": serialize_hand(self.round_manager.declarer_phase.kitty),
                "bid": bid,
                "giruda": serialize_giruda(giruda),
            })
            for i in range(5):
                if i != di:
                    await self.seats[i].send({
                        "type": "declarer_phase_start",
                        "declarer": di, "bid": bid,
                        "giruda": serialize_giruda(giruda),
                    })
            self._start_turn_timer(di)
        else:
            turn = bm.current_turn
            can_dm = bm.can_deal_miss(turn)
            await self._broadcast({
                "type": "bidding_turn", "seat": turn,
                "highest_bid": bm.highest_bid,
                "highest_giruda": serialize_giruda(bm.highest_giruda),
                "can_deal_miss": can_dm,
            })
            self._start_turn_timer(turn)

    async def _handle_declarer(self, session: Session, seat: int, msg_type: str, msg: dict) -> None:
        if seat != self.round_manager.declarer_index:
            await session.send(error_msg("NOT_DECLARER", "Only the declarer can act"))
            return

        dp = self.round_manager.declarer_phase

        if msg_type == "skip_first_change":
            dp.skip_first_change()
            dp.reveal_kitty()
            await session.send({
                "type": "kitty_revealed",
                "hand": serialize_hand(dp.hand),
            })

        elif msg_type == "change_giruda_first":
            giruda = deserialize_giruda(msg.get("giruda", "none"))
            bid = msg.get("bid", dp.bid)
            if not dp.change_giruda_first(giruda, bid):
                await session.send(error_msg("INVALID_ACTION", "Invalid giruda change"))
                return
            dp.reveal_kitty()
            await session.send({
                "type": "kitty_revealed",
                "hand": serialize_hand(dp.hand),
                "giruda": serialize_giruda(dp.giruda),
                "bid": dp.bid,
            })

        elif msg_type == "change_giruda_second":
            giruda = deserialize_giruda(msg.get("giruda", "none"))
            bid = msg.get("bid", dp.bid)
            if not dp.change_giruda_second(giruda, bid):
                await session.send(error_msg("INVALID_ACTION", "Invalid giruda change"))
                return
            await session.send({
                "type": "giruda_changed",
                "giruda": serialize_giruda(dp.giruda),
                "bid": dp.bid,
            })

        elif msg_type == "finalize_declarer":
            discard_data = msg.get("discard", [])
            to_discard = deserialize_hand(discard_data)
            fc_data = msg.get("friend_call", {})
            friend_call = self._parse_friend_call(fc_data)

            if not dp.finalize(to_discard, friend_call):
                await session.send(error_msg("INVALID_ACTION", "Invalid finalization"))
                return

            self._cancel_turn_timer()
            self.round_manager.advance_from_declarer()

            fc_broadcast = self._serialize_friend_call()
            await self._broadcast({
                "type": "declarer_finalized",
                "declarer": seat,
                "bid": self.round_manager.bid,
                "giruda": serialize_giruda(self.round_manager.giruda),
                "friend_call": fc_broadcast,
            })
            await self._send_trick_turn()

    async def _handle_play(self, session: Session, seat: int, msg_type: str, msg: dict) -> None:
        tm = self.round_manager.trick_manager

        if msg_type == "play_card":
            if seat != tm.current_turn:
                await session.send(error_msg("NOT_YOUR_TURN", "It is not your turn"))
                return

            card = deserialize_card(msg.get("card", {}))
            joker_suit = msg.get("joker_suit")
            joker_call = msg.get("joker_call", False)

            success = False
            if joker_call:
                success = tm.play_card_with_joker_call(seat, card)
            elif card.is_joker and joker_suit is not None:
                suit_map = {"S": 0, "D": 1, "H": 2, "C": 3}
                ds = suit_map.get(joker_suit, -1)
                if ds >= 0:
                    success = tm.play_card_with_joker_suit(seat, card, ds)
            else:
                success = tm.play_card(seat, card)

            if not success:
                await session.send(error_msg("INVALID_CARD", "Cannot play that card"))
                return

            self._cancel_turn_timer()

            await self._broadcast({
                "type": "card_played", "seat": seat,
                "card": serialize_card(card),
            })

            if tm.friend_revealed and not hasattr(self, '_friend_announced'):
                self._friend_announced = True
                await self._broadcast({
                    "type": "friend_revealed",
                    "seat": tm.friend_index,
                    "name": self.seats[tm.friend_index].player_name,
                })

            if len(tm.current_trick) == 0 and tm.trick_number > 0:
                trick_num = tm.trick_number - 1
                await self._broadcast({
                    "type": "trick_result",
                    "trick_number": trick_num,
                    "winner": tm.last_trick_winner,
                })

            if tm.is_game_over():
                await self._end_round()
            else:
                if len(tm.current_trick) == 0:
                    await self._send_trick_turn()
                else:
                    self._start_turn_timer(tm.current_turn)

    # --- Round lifecycle ---

    async def _start_round(self) -> None:
        self.state = RoomState.IN_GAME
        self._friend_announced = False
        if self.deal_miss_penalty is None:
            self.deal_miss_penalty = DealMissPenalty(5, self.options)

        self.round_manager = RoundManager(5, self.dealer_index, self.options.min_bid, self.options)
        self.round_manager.do_deal()

        self.deal_miss_penalty.record_game_played()

        for i in range(5):
            await self.seats[i].send({
                "type": "round_start",
                "dealer": self.dealer_index,
                "your_seat": i,
                "hand": serialize_hand(self.round_manager.hands[i]),
            })

        bm = self.round_manager.bidding_manager
        turn = bm.current_turn
        await self._broadcast({
            "type": "bidding_turn", "seat": turn,
            "highest_bid": 0, "highest_giruda": "none",
            "can_deal_miss": bm.can_deal_miss(turn),
        })
        self._start_turn_timer(turn)

    async def _end_round(self) -> None:
        self.round_manager.advance_from_play()
        scores = self.round_manager.calculate_scores()

        pot_claimed_by = -1
        pot_amount = 0
        if scores.get(self.round_manager.declarer_index, 0) > 0 and self.deal_miss_penalty.pot > 0:
            pot_claimed_by = self.round_manager.declarer_index
            pot_amount = self.deal_miss_penalty.claim_pot()
            self.cumulative_scores[pot_claimed_by] += pot_amount

        for i in range(5):
            self.cumulative_scores[i] += scores.get(i, 0)

        tm = self.round_manager.trick_manager
        await self._broadcast({
            "type": "round_result",
            "declarer": self.round_manager.declarer_index,
            "friend": tm.friend_index if tm.friend_revealed else -1,
            "friend_revealed": tm.friend_revealed,
            "bid": self.round_manager.bid,
            "back_run": scores.get("back_run", False),
            "score_changes": scores,
            "total_scores": list(self.cumulative_scores),
            "pot_claimed_by": pot_claimed_by,
            "pot_amount": pot_amount,
        })

        from game.dealer_selector import next_dealer
        ruling_won = scores.get(self.round_manager.declarer_index, 0) > 0
        friend_idx = tm.friend_index if tm.friend_revealed else -1
        self.dealer_index = next_dealer(ruling_won, self.round_manager.declarer_index, friend_idx)

        self.state = RoomState.BETWEEN_ROUNDS

    async def _handle_between_rounds(self, session: Session, msg_type: str, msg: dict) -> None:
        if msg_type == "start_game":
            if session.session_id != self.host_session_id:
                await session.send(error_msg("NOT_HOST", "Only the host can start"))
                return
            await self._start_round()

    # --- Trick turn broadcast ---

    async def _send_trick_turn(self) -> None:
        tm = self.round_manager.trick_manager
        turn = tm.current_turn
        joker_call_card = None
        if tm.trick_number > 0 and tm.trick_number < 9:
            joker_call_card = True
        await self._broadcast({
            "type": "trick_turn",
            "trick_number": tm.trick_number,
            "seat": turn,
            "lead_suit": None,
            "cards_played": [],
        })
        self._start_turn_timer(turn)

    # --- Turn timer ---

    def _start_turn_timer(self, seat: int) -> None:
        self._cancel_turn_timer()
        self._turn_timer = asyncio.create_task(self._turn_timeout(seat))

    def _cancel_turn_timer(self) -> None:
        if self._turn_timer is not None:
            self._turn_timer.cancel()
            self._turn_timer = None

    async def _turn_timeout(self, seat: int) -> None:
        await asyncio.sleep(TURN_TIMEOUT)
        rm = self.round_manager
        if rm is None:
            return
        if rm.phase == Phase.BIDDING:
            bm = rm.bidding_manager
            if bm.current_turn == seat:
                bm.pass_turn(seat)
                await self._broadcast({"type": "bid_passed", "seat": seat, "timeout": True})
                await self._check_bidding_end()
        elif rm.phase == Phase.PLAY:
            tm = rm.trick_manager
            if tm.current_turn == seat:
                hand = tm.states[seat].hand
                for card in hand:
                    if tm.play_card(seat, card):
                        await self._broadcast({
                            "type": "card_played", "seat": seat,
                            "card": serialize_card(card), "timeout": True,
                        })
                        if tm.is_game_over():
                            await self._end_round()
                        elif len(tm.current_trick) == 0:
                            await self._send_trick_turn()
                        else:
                            self._start_turn_timer(tm.current_turn)
                        break

    # --- Helpers ---

    def _apply_options(self, opts_dict: dict) -> None:
        for key, val in opts_dict.items():
            if hasattr(self.options, key):
                setattr(self.options, key, val)

    def _parse_friend_call(self, data: dict) -> dict:
        fc_type = data.get("type", "no_friend")
        if fc_type == "card":
            return {
                "type": FriendCallType.CARD,
                "card": deserialize_card(data["card"]),
            }
        elif fc_type == "first_trick_winner":
            return {"type": FriendCallType.FIRST_TRICK_WINNER}
        elif fc_type == "player":
            return {"type": FriendCallType.PLAYER, "player_index": data["seat"]}
        return {"type": FriendCallType.NO_FRIEND}

    def _serialize_friend_call(self) -> dict:
        fc = self.round_manager.friend_call
        fc_type = fc["type"]
        if fc_type == FriendCallType.CARD:
            return {"type": "card", "card": serialize_card(fc["card"])}
        elif fc_type == FriendCallType.FIRST_TRICK_WINNER:
            return {"type": "first_trick_winner"}
        elif fc_type == FriendCallType.PLAYER:
            return {"type": "player", "seat": fc["player_index"]}
        return {"type": "no_friend"}

    async def _broadcast(self, msg: dict) -> None:
        for s in self.seats:
            if s is not None and s.connected:
                await s.send(msg)

    # --- Join ---

    async def try_join(self, session: Session) -> bool:
        if self.state != RoomState.LOBBY:
            await session.send(error_msg("GAME_IN_PROGRESS", "Game already in progress"))
            return False
        if self.player_count() >= 5:
            await session.send(error_msg("ROOM_FULL", "Room is full"))
            return False
        seat = self._add_player(session)
        if seat is None:
            await session.send(error_msg("ROOM_FULL", "Room is full"))
            return False
        await session.send({
            "type": "room_joined",
            "code": self.code,
            "seat": seat,
            "players": self._get_players_info(),
        })
        await self._broadcast_except(session, {
            "type": "player_joined",
            "seat": seat,
            "name": session.player_name,
        })
        return True

    async def _broadcast_except(self, exclude: Session, msg: dict) -> None:
        for s in self.seats:
            if s is not None and s is not exclude and s.connected:
                await s.send(msg)

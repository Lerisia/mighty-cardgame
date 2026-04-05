from __future__ import annotations
from .card import Card, Suit, Rank
from .bidding_state import Giruda
from .declarer_phase import FriendCallType
from .card_validator import can_lead, can_follow, is_mighty
from .trick_judge import determine_winner
from .play_state import PlayState, Role
from .game_options import GameOptions

TOTAL_TRICKS = 10
DEFAULT_JOKER_CALL_SUIT = Suit.CLUB
DEFAULT_JOKER_CALL_RANK = Rank.THREE


class TrickManager:
    def __init__(self, states: list[PlayState], declarer: int, giruda: int,
                 friend_call: dict, options: GameOptions | None = None) -> None:
        self.states = states
        self.player_count = len(states)
        self.declarer_index = declarer
        self.giruda = giruda
        self.friend_call = friend_call
        self.options = options or GameOptions()
        self.trick_number = 0
        self.current_turn = declarer
        self.current_trick: list[Card] = []
        self.current_trick_players: list[int] = []
        self.lead_suit = -1
        self.joker_called = False
        self.last_trick_winner = -1
        self.friend_index = -1
        self.friend_revealed = False
        self.face_down_pile: list[Card] = []

        states[declarer].role = Role.DECLARER

        if friend_call["type"] == FriendCallType.CARD:
            for i in range(self.player_count):
                if i == declarer:
                    continue
                for card in states[i].hand:
                    if self._matches_friend_card(card):
                        states[i].is_friend = True
                        break
        elif friend_call["type"] == FriendCallType.PLAYER:
            fi = friend_call["player_index"]
            states[fi].is_friend = True

    def is_game_over(self) -> bool:
        return self.trick_number >= TOTAL_TRICKS

    def play_card(self, player_index: int, card: Card) -> bool:
        if player_index != self.current_turn:
            return False
        state = self.states[player_index]
        if card not in state.hand:
            return False

        is_lead = len(self.current_trick) == 0

        if is_lead:
            if not can_lead(card, state.hand, self.giruda, self.trick_number, self.options):
                return False
        else:
            if not can_follow(card, state.hand, self.lead_suit, self.giruda,
                              self.joker_called, self.options):
                return False

        state.play_card(card)
        self.current_trick.append(card)
        self.current_trick_players.append(player_index)

        if is_lead and not card.is_joker:
            self.lead_suit = card.suit

        self._check_friend_reveal(player_index, card)

        if len(self.current_trick) == self.player_count:
            self._resolve_trick()
        else:
            self._advance_turn()
        return True

    def play_card_with_joker_suit(self, player_index: int, card: Card,
                                  designated_suit: int) -> bool:
        if player_index != self.current_turn:
            return False
        if not card.is_joker:
            return False
        if len(self.current_trick) != 0:
            return False
        state = self.states[player_index]
        if card not in state.hand:
            return False

        state.play_card(card)
        self.current_trick.append(card)
        self.current_trick_players.append(player_index)
        self.lead_suit = designated_suit

        self._check_friend_reveal(player_index, card)

        if len(self.current_trick) == self.player_count:
            self._resolve_trick()
        else:
            self._advance_turn()
        return True

    def play_card_with_joker_call(self, player_index: int, card: Card) -> bool:
        if player_index != self.current_turn:
            return False
        if len(self.current_trick) != 0:
            return False
        if self.trick_number == 0 or self.trick_number == 9:
            return False
        if not self._is_joker_call_card(card):
            return False
        self.joker_called = True
        return self.play_card(player_index, card)

    def _is_joker_call_card(self, card: Card) -> bool:
        if card.is_joker:
            return False
        if self.giruda == Giruda.CLUB:
            return (card.suit == self.options.alter_joker_call_suit and
                    card.rank == self.options.alter_joker_call_rank)
        return card.suit == DEFAULT_JOKER_CALL_SUIT and card.rank == DEFAULT_JOKER_CALL_RANK

    def _resolve_trick(self) -> None:
        winner = determine_winner(
            self.current_trick, self.current_trick_players,
            self.lead_suit, self.giruda, self.trick_number,
            self.joker_called, self.options
        )
        self.last_trick_winner = winner

        if self._is_ruling_party(winner):
            self.face_down_pile.extend(self.current_trick)
        else:
            for card in self.current_trick:
                if card.is_point_card:
                    self.states[winner].point_cards.append(card)
                else:
                    self.face_down_pile.append(card)

        if (not self.friend_revealed and
                self.friend_call["type"] == FriendCallType.FIRST_TRICK_WINNER):
            if self.trick_number == 0 and winner != self.declarer_index:
                self._reveal_friend(winner)

        if not self.friend_revealed and self.options.allow_last_trick_friend:
            if self.trick_number == TOTAL_TRICKS - 1 and winner != self.declarer_index:
                self._reveal_friend(winner)

        self.trick_number += 1
        self.current_trick = []
        self.current_trick_players = []
        self.joker_called = False
        self.lead_suit = -1
        self.current_turn = self.last_trick_winner

    def _reveal_friend(self, player_index: int) -> None:
        self.friend_index = player_index
        self.friend_revealed = True
        self.states[player_index].is_friend = True
        self.states[player_index].role = Role.FRIEND
        moved = self.states[player_index].clear_point_cards()
        self.face_down_pile.extend(moved)

    def _check_friend_reveal(self, player_index: int, card: Card) -> None:
        if self.friend_revealed:
            return
        if self.friend_call["type"] != FriendCallType.CARD:
            return
        if self._matches_friend_card(card):
            self._reveal_friend(player_index)

    def _matches_friend_card(self, card: Card) -> bool:
        fc = self.friend_call["card"]
        if card.is_joker and fc.is_joker:
            return True
        if not card.is_joker and not fc.is_joker:
            return card.suit == fc.suit and card.rank == fc.rank
        return False

    def _is_ruling_party(self, player_index: int) -> bool:
        if player_index == self.declarer_index:
            return True
        if self.friend_revealed and player_index == self.friend_index:
            return True
        return False

    def _advance_turn(self) -> None:
        self.current_turn = (self.current_turn + 1) % self.player_count

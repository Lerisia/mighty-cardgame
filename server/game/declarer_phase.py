from __future__ import annotations
from enum import IntEnum
from .card import Card
from .bidding_state import Giruda
from .game_options import GameOptions


class FriendCallType(IntEnum):
    CARD = 0
    FIRST_TRICK_WINNER = 1
    NO_FRIEND = 2
    PLAYER = 3


class DeclarerPhase:
    def __init__(self, hand: list[Card], kitty: list[Card], bid: int, giruda: int,
                 options: GameOptions | None = None) -> None:
        self.hand = list(hand)
        self.kitty = kitty
        self.bid = bid
        self.giruda = giruda
        self.options = options or GameOptions()
        self.discarded: list[Card] = []
        self.first_change_used = False
        self.kitty_revealed = False
        self.is_finished = False
        self.friend_call_type: int = -1
        self.friend_call_card: Card | None = None
        self.friend_call_player: int = -1

    def change_giruda_first(self, new_giruda: int, new_bid: int) -> bool:
        if self.first_change_used:
            return False
        if not self.options.allow_giruda_change_before_kitty:
            return False
        if not self._is_valid_change(new_giruda, new_bid, 1):
            return False
        self.giruda = new_giruda
        self.bid = new_bid
        self.first_change_used = True
        return True

    def skip_first_change(self) -> None:
        self.first_change_used = True

    def reveal_kitty(self) -> None:
        if not self.first_change_used:
            return
        self.kitty_revealed = True
        self.hand.extend(self.kitty)

    def change_giruda_second(self, new_giruda: int, new_bid: int) -> bool:
        if not self.kitty_revealed:
            return False
        if not self.options.allow_giruda_change_after_kitty:
            return False
        if not self._is_valid_change(new_giruda, new_bid, 2):
            return False
        self.giruda = new_giruda
        self.bid = new_bid
        return True

    def finalize(self, to_discard: list[Card], friend_call: dict) -> bool:
        if not self.kitty_revealed:
            return False
        if len(to_discard) != 3:
            return False
        call_type = friend_call["type"]
        if call_type == FriendCallType.PLAYER and not self.options.allow_player_friend:
            return False

        temp_hand = list(self.hand)
        for card in to_discard:
            try:
                temp_hand.remove(card)
            except ValueError:
                return False

        if call_type == FriendCallType.CARD:
            fc = friend_call["card"]
            if not self.options.allow_fake_friend:
                if self._is_fake_friend(fc, temp_hand, to_discard):
                    return False

        self.hand = temp_hand
        self.discarded = to_discard
        self.friend_call_type = call_type
        if call_type == FriendCallType.CARD:
            self.friend_call_card = friend_call["card"]
        elif call_type == FriendCallType.PLAYER:
            self.friend_call_player = friend_call["player_index"]
        self.is_finished = True
        return True

    def _is_fake_friend(self, card: Card, remaining_hand: list[Card],
                        discarded: list[Card]) -> bool:
        for c in remaining_hand:
            if self._card_matches(c, card):
                return True
        for c in discarded:
            if self._card_matches(c, card):
                return True
        return False

    @staticmethod
    def _card_matches(a: Card, b: Card) -> bool:
        if a.is_joker and b.is_joker:
            return True
        if not a.is_joker and not b.is_joker:
            return a.suit == b.suit and a.rank == b.rank
        return False

    def _is_valid_change(self, new_giruda: int, new_bid: int, raise_amount: int) -> bool:
        if new_giruda == Giruda.NO_GIRUDA:
            return new_bid >= self.bid + raise_amount - 1
        return new_bid >= self.bid + raise_amount

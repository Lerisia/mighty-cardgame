from __future__ import annotations
from .card import Card
from .bidding_state import BiddingState, Giruda
from .deal_miss import can_declare
from .game_options import GameOptions


class BiddingManager:
    def __init__(self, player_count: int, dealer_index: int, hands: list[list[Card]],
                 minimum_bid: int = 13, options: GameOptions | None = None) -> None:
        self.player_count = player_count
        self.current_turn = dealer_index
        self.hands = hands
        self.options = options or GameOptions()
        self.minimum_bid = self.options.min_bid if options else minimum_bid
        self.states = [BiddingState() for _ in range(player_count)]
        self.has_acted = [False] * player_count
        self.highest_bid = 0
        self.highest_giruda = Giruda.NONE
        self.highest_bidder = -1
        self.deal_miss_declared = False
        self.deal_miss_player = -1

    def place_bid(self, player_index: int, count: int, giruda: int) -> bool:
        if player_index != self.current_turn:
            return False
        if self.states[player_index].passed:
            return False
        if count < self.minimum_bid:
            return False
        if not self._is_higher_bid(count, giruda):
            return False
        if not self.states[player_index].place_bid(count, giruda):
            return False
        self.highest_bid = count
        self.highest_giruda = giruda
        self.highest_bidder = player_index
        self.has_acted[player_index] = True
        self._advance_turn()
        return True

    def pass_turn(self, player_index: int) -> bool:
        if player_index != self.current_turn:
            return False
        if self.states[player_index].passed:
            return False
        self.states[player_index].pass_bid()
        self.has_acted[player_index] = True
        self._advance_turn()
        return True

    def can_deal_miss(self, player_index: int) -> bool:
        if self.has_acted[player_index]:
            return False
        return can_declare(self.hands[player_index], self.options)

    def declare_deal_miss(self, player_index: int) -> bool:
        if not self.can_deal_miss(player_index):
            return False
        self.deal_miss_declared = True
        self.deal_miss_player = player_index
        return True

    def is_finished(self) -> bool:
        if self.highest_bidder < 0:
            return False
        active = sum(1 for s in self.states if not s.passed)
        return active <= 1

    def is_last_player_standing(self) -> bool:
        active = sum(1 for s in self.states if not s.passed)
        return active == 1

    def get_last_standing_player(self) -> int:
        for i in range(self.player_count):
            if not self.states[i].passed:
                return i
        return -1

    def get_declarer(self) -> int:
        return self.highest_bidder

    def _is_higher_bid(self, count: int, giruda: int) -> bool:
        if self.highest_bid == 0:
            return True
        if count > self.highest_bid:
            return True
        if count == self.highest_bid:
            if giruda == Giruda.NO_GIRUDA and self.highest_giruda != Giruda.NO_GIRUDA:
                return True
        return False

    def _advance_turn(self) -> None:
        for _ in range(self.player_count - 1):
            self.current_turn = (self.current_turn + 1) % self.player_count
            if not self.states[self.current_turn].passed:
                return

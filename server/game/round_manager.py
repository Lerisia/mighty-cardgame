from __future__ import annotations
from enum import IntEnum
from .deck import Deck
from .play_state import PlayState
from .bidding_manager import BiddingManager
from .declarer_phase import DeclarerPhase, FriendCallType
from .trick_manager import TrickManager
from .score_calculator import calculate as calc_scores
from .bidding_state import Giruda
from .game_options import GameOptions


class Phase(IntEnum):
    DEAL = 0
    BIDDING = 1
    DECLARER = 2
    PLAY = 3
    SCORING = 4
    FINISHED = 5


class RoundManager:
    def __init__(self, player_count: int, dealer_index: int, min_bid: int = 13,
                 options: GameOptions | None = None) -> None:
        self.player_count = player_count
        self.dealer_index = dealer_index
        self.min_bid = min_bid
        self.options = options or GameOptions()
        self.phase = Phase.DEAL
        self.kitty: list = []
        self.hands: list = []
        self.bidding_manager: BiddingManager | None = None
        self.declarer_phase: DeclarerPhase | None = None
        self.trick_manager: TrickManager | None = None
        self.declarer_index = -1
        self.bid = 0
        self.giruda = Giruda.NONE
        self.friend_call: dict = {}
        self.no_friend = False

    def do_deal(self) -> None:
        if self.phase != Phase.DEAL:
            return
        deck = Deck()
        result = deck.deal(self.player_count)
        self.hands = result["hands"]
        self.kitty = result["kitty"]
        bidding_hands = [list(h) for h in self.hands]
        self.bidding_manager = BiddingManager(
            self.player_count, self.dealer_index, bidding_hands,
            self.min_bid, self.options
        )
        self.phase = Phase.BIDDING

    def advance_from_bidding(self) -> bool:
        if self.phase != Phase.BIDDING:
            return False
        if not self.bidding_manager.is_finished():
            return False
        self.declarer_index = self.bidding_manager.get_declarer()
        self.bid = self.bidding_manager.states[self.declarer_index].bid_count
        self.giruda = self.bidding_manager.states[self.declarer_index].bid_giruda
        self.declarer_phase = DeclarerPhase(
            self.hands[self.declarer_index], self.kitty,
            self.bid, self.giruda, self.options
        )
        self.phase = Phase.DECLARER
        return True

    def advance_from_declarer(self) -> bool:
        if self.phase != Phase.DECLARER:
            return False
        if not self.declarer_phase.is_finished:
            return False
        self.bid = self.declarer_phase.bid
        self.giruda = self.declarer_phase.giruda
        self.friend_call = {"type": self.declarer_phase.friend_call_type}
        if self.declarer_phase.friend_call_type == FriendCallType.CARD:
            self.friend_call["card"] = self.declarer_phase.friend_call_card
        elif self.declarer_phase.friend_call_type == FriendCallType.PLAYER:
            self.friend_call["player_index"] = self.declarer_phase.friend_call_player
        self.no_friend = self.declarer_phase.friend_call_type == FriendCallType.NO_FRIEND
        self.hands[self.declarer_index] = self.declarer_phase.hand
        states = []
        for i in range(self.player_count):
            st = PlayState()
            st.hand = self.hands[i]
            states.append(st)
        states[self.declarer_index].set_discarded(self.declarer_phase.discarded)
        self.trick_manager = TrickManager(
            states, self.declarer_index, self.giruda,
            self.friend_call, self.options
        )
        self.trick_manager.face_down_pile.extend(self.declarer_phase.discarded)
        self.phase = Phase.PLAY
        return True

    def advance_from_play(self) -> bool:
        if self.phase != Phase.PLAY:
            return False
        if not self.trick_manager.is_game_over():
            return False
        self.phase = Phase.SCORING
        return True

    def calculate_scores(self) -> dict:
        if self.phase != Phase.SCORING:
            return {}
        opposition_points = 0
        for i in range(self.player_count):
            if not self.trick_manager._is_ruling_party(i):
                opposition_points += self.trick_manager.states[i].get_point_count()
        ruling_points = 20 - opposition_points
        is_no_giruda = self.giruda == Giruda.NO_GIRUDA

        result = calc_scores(self.bid, ruling_points, self.options.min_bid,
                             self.no_friend, is_no_giruda, self.options)

        actual_friend = -1
        if not self.no_friend:
            if self.trick_manager.friend_revealed:
                actual_friend = self.trick_manager.friend_index
            else:
                for i in range(self.player_count):
                    if i != self.declarer_index and self.trick_manager.states[i].is_friend:
                        actual_friend = i
                        break

        effective_no_friend = self.no_friend or actual_friend < 0
        if effective_no_friend and not self.no_friend:
            result = calc_scores(self.bid, ruling_points, self.options.min_bid,
                                 True, is_no_giruda, self.options)

        scores = {}
        for i in range(self.player_count):
            if i == self.declarer_index:
                scores[i] = result["declarer"]
            elif not effective_no_friend and i == actual_friend:
                scores[i] = result["friend"]
            else:
                scores[i] = result["opposition"]

        self.phase = Phase.FINISHED
        return scores

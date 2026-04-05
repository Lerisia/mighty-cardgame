from __future__ import annotations
from dataclasses import dataclass, field
from enum import IntEnum
from .card import Suit, Rank


class BackRunMethod(IntEnum):
    RULING_PARTY_10_OR_LESS = 0
    OPPOSITION_GETS_BID_OR_MORE = 1


class DealMissPenalty(IntEnum):
    FIXED = 0
    DOUBLING = 1


class DealMissThreshold(IntEnum):
    LESS_THAN = 0
    LESS_OR_EQUAL = 1


class SuitDisplay(IntEnum):
    ENGLISH = 0
    KOREAN = 1
    SHORT_KOREAN = 2


@dataclass
class GameOptions:
    # Bidding
    min_bid: int = 13
    allow_giruda_change_before_kitty: bool = True
    allow_giruda_change_after_kitty: bool = True
    bid_20_run_double: bool = False

    # Friend
    allow_player_friend: bool = True
    allow_fake_friend: bool = True
    allow_last_trick_friend: bool = False

    # Special Cards
    alter_mighty_suit: int = Suit.DIAMOND
    alter_mighty_rank: int = Rank.ACE
    alter_joker_call_suit: int = Suit.SPADE
    alter_joker_call_rank: int = Rank.THREE
    first_trick_mighty_effect: bool = True
    last_trick_mighty_effect: bool = True
    first_trick_joker_effect: bool = False
    last_trick_joker_effect: bool = False
    joker_called_joker_effect: bool = False

    # Scoring
    back_run_method: int = BackRunMethod.RULING_PARTY_10_OR_LESS

    # Deal Miss
    deal_miss_penalty_method: int = DealMissPenalty.DOUBLING
    deal_miss_fixed_penalty: int = 5
    deal_miss_doubling_base: int = 2
    deal_miss_dealer_to_declarer: bool = True
    deal_miss_threshold: float = 1.0
    deal_miss_threshold_type: int = DealMissThreshold.LESS_THAN
    deal_miss_joker_score: float = -1.0
    deal_miss_mighty_score: float = 0.0
    deal_miss_ten_score: float = 0.5
    deal_miss_point_card_score: float = 1.0
    deal_miss_non_point_score: float = 0.0

    # Display
    suit_display_style: int = SuitDisplay.ENGLISH

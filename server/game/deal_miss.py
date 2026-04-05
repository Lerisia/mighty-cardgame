from __future__ import annotations
from .card import Card, Suit, Rank
from .game_options import GameOptions, DealMissThreshold


def card_score(card: Card, options: GameOptions | None = None) -> float:
    if options is None:
        options = GameOptions()
    if card.is_joker:
        return options.deal_miss_joker_score
    if card.suit == Suit.SPADE and card.rank == Rank.ACE:
        return options.deal_miss_mighty_score
    if card.rank == Rank.TEN:
        return options.deal_miss_ten_score
    if card.is_point_card:
        return options.deal_miss_point_card_score
    return options.deal_miss_non_point_score


def hand_score(hand: list[Card], options: GameOptions | None = None) -> float:
    if options is None:
        options = GameOptions()
    return sum(card_score(c, options) for c in hand)


def can_declare(hand: list[Card], options: GameOptions | None = None) -> bool:
    if options is None:
        options = GameOptions()
    score = hand_score(hand, options)
    if options.deal_miss_threshold_type == DealMissThreshold.LESS_THAN:
        return score < options.deal_miss_threshold
    return score <= options.deal_miss_threshold

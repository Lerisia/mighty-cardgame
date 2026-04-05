from __future__ import annotations
from .card import Card, Suit, Rank
from .bidding_state import Giruda
from .game_options import GameOptions

DEFAULT_MIGHTY_SUIT = Suit.SPADE
DEFAULT_MIGHTY_RANK = Rank.ACE


def is_mighty(card: Card, giruda: int, options: GameOptions | None = None) -> bool:
    if options is None:
        options = GameOptions()
    if card.is_joker:
        return False
    if giruda == Giruda.SPADE:
        return card.suit == options.alter_mighty_suit and card.rank == options.alter_mighty_rank
    return card.suit == DEFAULT_MIGHTY_SUIT and card.rank == DEFAULT_MIGHTY_RANK


def can_lead(card: Card, hand: list[Card], giruda: int, trick_number: int,
             options: GameOptions | None = None) -> bool:
    if options is None:
        options = GameOptions()
    if trick_number != 0:
        return True
    if is_mighty(card, giruda, options):
        return True
    giruda_suit = _giruda_to_suit(giruda)
    if card.is_joker:
        return _hand_only_giruda_and_joker(hand, giruda_suit)
    if giruda != Giruda.NO_GIRUDA and card.suit == giruda_suit:
        if _has_non_giruda_lead_option(hand, giruda_suit, giruda, options):
            return False
        return True
    return True


def can_follow(card: Card, hand: list[Card], lead_suit: int, giruda: int,
               joker_called: bool, options: GameOptions | None = None) -> bool:
    if options is None:
        options = GameOptions()
    if joker_called:
        return _can_follow_joker_call(card, hand, giruda, options)
    if is_mighty(card, giruda, options):
        return True
    if card.is_joker:
        return True
    has_lead = _has_suit_in_hand(hand, lead_suit, giruda, options)
    if not has_lead:
        return True
    if not card.is_joker and card.suit == lead_suit:
        return True
    return False


def _can_follow_joker_call(card: Card, hand: list[Card], giruda: int,
                           options: GameOptions) -> bool:
    has_joker = any(c.is_joker for c in hand)
    if not has_joker:
        return True
    if card.is_joker:
        return True
    if is_mighty(card, giruda, options):
        return True
    return False


def _has_suit_in_hand(hand: list[Card], suit: int, giruda: int,
                      options: GameOptions) -> bool:
    for card in hand:
        if card.is_joker:
            continue
        if is_mighty(card, giruda, options):
            if card.suit == suit:
                return True
            continue
        if card.suit == suit:
            return True
    return False


def _has_non_giruda_lead_option(hand: list[Card], giruda_suit: int, giruda: int,
                                options: GameOptions) -> bool:
    for card in hand:
        if card.is_joker:
            continue
        if is_mighty(card, giruda, options):
            return True
        if card.suit != giruda_suit:
            return True
    return False


def _hand_only_giruda_and_joker(hand: list[Card], giruda_suit: int) -> bool:
    for card in hand:
        if card.is_joker:
            continue
        if card.suit != giruda_suit:
            return False
    return True


def _giruda_to_suit(giruda: int) -> int:
    mapping = {
        Giruda.SPADE: Suit.SPADE,
        Giruda.DIAMOND: Suit.DIAMOND,
        Giruda.HEART: Suit.HEART,
        Giruda.CLUB: Suit.CLUB,
    }
    return mapping.get(giruda, -1)

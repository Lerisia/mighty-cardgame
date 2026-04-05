from __future__ import annotations
from .card import Card, Suit
from .bidding_state import Giruda
from .card_validator import is_mighty, _giruda_to_suit
from .game_options import GameOptions

LAST_TRICK = 9


def determine_winner(trick: list[Card], players: list[int], lead_suit: int,
                     giruda: int, trick_number: int, joker_called: bool,
                     options: GameOptions | None = None) -> int:
    if options is None:
        options = GameOptions()
    best_index = 0
    best_score = _card_strength(trick[0], lead_suit, giruda, trick_number, joker_called, options)
    for i in range(1, len(trick)):
        score = _card_strength(trick[i], lead_suit, giruda, trick_number, joker_called, options)
        if score > best_score:
            best_score = score
            best_index = i
    return players[best_index]


def _card_strength(card: Card, lead_suit: int, giruda: int, trick_number: int,
                   joker_called: bool, options: GameOptions) -> int:
    if is_mighty(card, giruda, options):
        if _is_mighty_nullified(trick_number, options):
            pass
        else:
            return 1000

    if card.is_joker:
        if _is_joker_nullified(trick_number, joker_called, options):
            return -1
        return 900

    giruda_suit = _giruda_to_suit(giruda)
    if giruda != Giruda.NO_GIRUDA and card.suit == giruda_suit:
        return 200 + int(card.rank)

    if card.suit == lead_suit:
        return 100 + int(card.rank)

    return 0


def _is_mighty_nullified(trick_number: int, options: GameOptions) -> bool:
    if trick_number == 0 and not options.first_trick_mighty_effect:
        return True
    if trick_number == LAST_TRICK and not options.last_trick_mighty_effect:
        return True
    return False


def _is_joker_nullified(trick_number: int, joker_called: bool, options: GameOptions) -> bool:
    if trick_number == 0 and not options.first_trick_joker_effect:
        return True
    if trick_number == LAST_TRICK and not options.last_trick_joker_effect:
        return True
    if joker_called and not options.joker_called_joker_effect:
        return True
    return False

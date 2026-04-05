from __future__ import annotations
from enum import IntEnum
from .card import Card


class Role(IntEnum):
    OPPOSITION = 0
    DECLARER = 1
    FRIEND = 2


class PlayState:
    def __init__(self) -> None:
        self.role: int = Role.OPPOSITION
        self.hand: list[Card] = []
        self.point_cards: list[Card] = []
        self.discarded: list[Card] = []
        self.is_friend: bool = False

    def play_card(self, card: Card) -> bool:
        try:
            self.hand.remove(card)
            return True
        except ValueError:
            return False

    def add_point_cards(self, cards: list[Card]) -> None:
        for card in cards:
            if card.is_point_card:
                self.point_cards.append(card)

    def get_point_count(self) -> int:
        return len(self.point_cards)

    def clear_point_cards(self) -> list[Card]:
        cards = list(self.point_cards)
        self.point_cards = []
        return cards

    def set_discarded(self, cards: list[Card]) -> None:
        self.discarded = cards

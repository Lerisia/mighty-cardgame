from __future__ import annotations
from dataclasses import dataclass
from enum import IntEnum


class Suit(IntEnum):
    SPADE = 0
    DIAMOND = 1
    HEART = 2
    CLUB = 3


class Rank(IntEnum):
    TWO = 2
    THREE = 3
    FOUR = 4
    FIVE = 5
    SIX = 6
    SEVEN = 7
    EIGHT = 8
    NINE = 9
    TEN = 10
    JACK = 11
    QUEEN = 12
    KING = 13
    ACE = 14


@dataclass(frozen=True)
class Card:
    suit: Suit = Suit.SPADE
    rank: Rank = Rank.TWO
    is_joker: bool = False

    @property
    def is_point_card(self) -> bool:
        if self.is_joker:
            return False
        return self.rank >= Rank.TEN

    def __str__(self) -> str:
        if self.is_joker:
            return "Joker"
        suit_str = ["S", "D", "H", "C"][self.suit]
        rank_map = {Rank.JACK: "J", Rank.QUEEN: "Q", Rank.KING: "K", Rank.ACE: "A"}
        rank_str = rank_map.get(self.rank, str(int(self.rank)))
        return f"{suit_str}{rank_str}"

    @staticmethod
    def joker() -> Card:
        return Card(Suit.SPADE, Rank.TWO, is_joker=True)

    def serialize(self) -> dict:
        if self.is_joker:
            return {"joker": True}
        return {"suit": ["S", "D", "H", "C"][self.suit], "rank": int(self.rank)}

    @staticmethod
    def deserialize(data: dict) -> Card:
        if data.get("joker"):
            return Card.joker()
        suit_map = {"S": Suit.SPADE, "D": Suit.DIAMOND, "H": Suit.HEART, "C": Suit.CLUB}
        return Card(suit_map[data["suit"]], Rank(data["rank"]))

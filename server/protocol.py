from __future__ import annotations
from game.card import Card, Suit, Rank
from game.bidding_state import Giruda


GIRUDA_TO_STR = {
    Giruda.NONE: "none",
    Giruda.SPADE: "S",
    Giruda.DIAMOND: "D",
    Giruda.HEART: "H",
    Giruda.CLUB: "C",
    Giruda.NO_GIRUDA: "no_giruda",
}

STR_TO_GIRUDA = {v: k for k, v in GIRUDA_TO_STR.items()}


def serialize_card(card: Card) -> dict:
    return card.serialize()


def deserialize_card(data: dict) -> Card:
    return Card.deserialize(data)


def serialize_hand(hand: list[Card]) -> list[dict]:
    return [serialize_card(c) for c in hand]


def deserialize_hand(data: list[dict]) -> list[Card]:
    return [deserialize_card(d) for d in data]


def serialize_giruda(giruda: int) -> str:
    return GIRUDA_TO_STR.get(giruda, "none")


def deserialize_giruda(s: str) -> int:
    return STR_TO_GIRUDA.get(s, Giruda.NONE)


def error_msg(code: str, message: str) -> dict:
    return {"type": "error", "code": code, "message": message}

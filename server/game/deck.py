from __future__ import annotations
import random
from .card import Card, Suit, Rank


class Deck:
    def __init__(self) -> None:
        self.cards: list[Card] = []
        for suit in Suit:
            for rank in Rank:
                self.cards.append(Card(suit, rank))
        self.cards.append(Card.joker())

    def shuffle(self) -> None:
        random.shuffle(self.cards)

    def deal(self, player_count: int) -> dict:
        self.shuffle()
        total_deal = len(self.cards) - (len(self.cards) % player_count)
        per_player = total_deal // player_count
        hands = []
        for i in range(player_count):
            hands.append(list(self.cards[i * per_player : (i + 1) * per_player]))
        kitty = list(self.cards[total_deal:])
        return {"hands": hands, "kitty": kitty}

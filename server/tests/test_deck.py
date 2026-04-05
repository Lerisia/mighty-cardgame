from game.deck import Deck
from game.card import Card


def test_deck_has_53_cards():
    d = Deck()
    assert len(d.cards) == 53


def test_deck_has_one_joker():
    d = Deck()
    jokers = [c for c in d.cards if c.is_joker]
    assert len(jokers) == 1


def test_deal_five_players():
    d = Deck()
    result = d.deal(5)
    assert len(result["hands"]) == 5
    for hand in result["hands"]:
        assert len(hand) == 10
    assert len(result["kitty"]) == 3


def test_deal_total_cards():
    d = Deck()
    result = d.deal(5)
    total = sum(len(h) for h in result["hands"]) + len(result["kitty"])
    assert total == 53


def test_deal_no_duplicates():
    d = Deck()
    result = d.deal(5)
    all_cards = []
    for hand in result["hands"]:
        all_cards.extend(hand)
    all_cards.extend(result["kitty"])
    assert len(set(id(c) for c in all_cards)) == 53

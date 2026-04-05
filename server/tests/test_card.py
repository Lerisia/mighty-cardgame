from game.card import Card, Suit, Rank


def test_point_card_ten():
    assert Card(Suit.HEART, Rank.TEN).is_point_card is True


def test_point_card_jack():
    assert Card(Suit.HEART, Rank.JACK).is_point_card is True


def test_point_card_queen():
    assert Card(Suit.HEART, Rank.QUEEN).is_point_card is True


def test_point_card_king():
    assert Card(Suit.HEART, Rank.KING).is_point_card is True


def test_point_card_ace():
    assert Card(Suit.HEART, Rank.ACE).is_point_card is True


def test_non_point_card():
    assert Card(Suit.CLUB, Rank.FIVE).is_point_card is False


def test_joker_not_point():
    assert Card.joker().is_point_card is False


def test_str_normal():
    assert str(Card(Suit.SPADE, Rank.ACE)) == "SA"


def test_str_joker():
    assert str(Card.joker()) == "Joker"


def test_str_number():
    assert str(Card(Suit.HEART, Rank.TEN)) == "H10"


def test_serialize_normal():
    assert Card(Suit.SPADE, Rank.ACE).serialize() == {"suit": "S", "rank": 14}


def test_serialize_joker():
    assert Card.joker().serialize() == {"joker": True}


def test_deserialize_normal():
    c = Card.deserialize({"suit": "H", "rank": 10})
    assert c.suit == Suit.HEART
    assert c.rank == Rank.TEN
    assert c.is_joker is False


def test_deserialize_joker():
    c = Card.deserialize({"joker": True})
    assert c.is_joker is True


def test_card_equality():
    a = Card(Suit.SPADE, Rank.ACE)
    b = Card(Suit.SPADE, Rank.ACE)
    assert a == b


def test_card_hashable():
    s = {Card(Suit.SPADE, Rank.ACE), Card(Suit.SPADE, Rank.ACE)}
    assert len(s) == 1

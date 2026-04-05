from game.card import Card, Suit, Rank
from game.deal_miss import card_score, hand_score, can_declare
from game.game_options import GameOptions, DealMissThreshold


def test_mighty_scores_zero():
    assert card_score(Card(Suit.SPADE, Rank.ACE)) == 0.0


def test_ten_scores_half():
    assert card_score(Card(Suit.HEART, Rank.TEN)) == 0.5


def test_joker_scores_negative_one():
    assert card_score(Card.joker()) == -1.0


def test_point_card_scores_one():
    for rank in [Rank.KING, Rank.QUEEN, Rank.JACK]:
        assert card_score(Card(Suit.HEART, rank)) == 1.0


def test_non_point_card_scores_zero():
    assert card_score(Card(Suit.CLUB, Rank.FIVE)) == 0.0


def test_hand_eligible():
    hand = [Card(Suit.CLUB, Rank(2 + i)) for i in range(8)]
    hand.append(Card.joker())
    hand.append(Card(Suit.DIAMOND, Rank.TWO))
    assert can_declare(hand) is True


def test_hand_not_eligible():
    hand = [
        Card(Suit.SPADE, Rank.ACE),
        Card(Suit.HEART, Rank.KING),
        Card(Suit.HEART, Rank.QUEEN),
    ]
    hand += [Card(Suit.CLUB, Rank(2 + i)) for i in range(7)]
    assert can_declare(hand) is False


def test_hand_exactly_one_point_not_eligible():
    hand = [Card(Suit.CLUB, Rank(2 + i)) for i in range(8)]
    hand.append(Card(Suit.DIAMOND, Rank.TWO))
    hand.append(Card(Suit.HEART, Rank.JACK))
    assert hand_score(hand) == 1.0
    assert can_declare(hand) is False


def test_custom_threshold_less_or_equal():
    opts = GameOptions()
    opts.deal_miss_threshold = 1.0
    opts.deal_miss_threshold_type = DealMissThreshold.LESS_OR_EQUAL
    hand = [Card(Suit.CLUB, Rank(2 + i)) for i in range(8)]
    hand.append(Card(Suit.DIAMOND, Rank.TWO))
    hand.append(Card(Suit.HEART, Rank.JACK))
    assert can_declare(hand, opts) is True

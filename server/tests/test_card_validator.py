from game.card import Card, Suit, Rank
from game.bidding_state import Giruda
from game.card_validator import is_mighty, can_lead, can_follow
from game.game_options import GameOptions

SA = Card(Suit.SPADE, Rank.ACE)
DA = Card(Suit.DIAMOND, Rank.ACE)
JOKER = Card.joker()


def test_mighty_spade_ace_default():
    assert is_mighty(SA, Giruda.HEART) is True


def test_mighty_diamond_ace_when_spade_giruda():
    assert is_mighty(DA, Giruda.SPADE) is True
    assert is_mighty(SA, Giruda.SPADE) is False


def test_joker_not_mighty():
    assert is_mighty(JOKER, Giruda.HEART) is False


def test_custom_alter_mighty():
    opts = GameOptions()
    opts.alter_mighty_suit = Suit.HEART
    opts.alter_mighty_rank = Rank.KING
    HK = Card(Suit.HEART, Rank.KING)
    assert is_mighty(DA, Giruda.SPADE, opts) is False
    assert is_mighty(HK, Giruda.SPADE, opts) is True
    assert is_mighty(SA, Giruda.HEART, opts) is True


def test_first_trick_cannot_lead_giruda():
    hand = [Card(Suit.SPADE, Rank.TWO), Card(Suit.HEART, Rank.THREE)]
    assert can_lead(hand[0], hand, Giruda.SPADE, 0) is False


def test_first_trick_can_lead_mighty():
    hand = [DA, Card(Suit.HEART, Rank.THREE)]
    assert can_lead(DA, hand, Giruda.SPADE, 0) is True


def test_first_trick_can_lead_non_giruda():
    hand = [Card(Suit.HEART, Rank.THREE), Card(Suit.SPADE, Rank.TWO)]
    assert can_lead(hand[0], hand, Giruda.SPADE, 0) is True


def test_must_follow_lead_suit():
    hand = [Card(Suit.HEART, Rank.TWO), Card(Suit.CLUB, Rank.THREE)]
    assert can_follow(hand[0], hand, Suit.HEART, Giruda.SPADE, False) is True
    assert can_follow(hand[1], hand, Suit.HEART, Giruda.SPADE, False) is False


def test_no_lead_suit_can_play_anything():
    hand = [Card(Suit.CLUB, Rank.THREE), Card(Suit.SPADE, Rank.FIVE)]
    assert can_follow(hand[0], hand, Suit.HEART, Giruda.SPADE, False) is True
    assert can_follow(hand[1], hand, Suit.HEART, Giruda.SPADE, False) is True


def test_mighty_can_always_follow():
    hand = [SA, Card(Suit.CLUB, Rank.THREE)]
    assert can_follow(SA, hand, Suit.HEART, Giruda.DIAMOND, False) is True


def test_joker_can_always_follow():
    hand = [JOKER, Card(Suit.CLUB, Rank.THREE)]
    assert can_follow(JOKER, hand, Suit.HEART, Giruda.SPADE, False) is True


def test_joker_call_forces_joker():
    hand = [JOKER, Card(Suit.CLUB, Rank.FIVE)]
    assert can_follow(hand[1], hand, Suit.CLUB, Giruda.SPADE, True) is False
    assert can_follow(JOKER, hand, Suit.CLUB, Giruda.SPADE, True) is True

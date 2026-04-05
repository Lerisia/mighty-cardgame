from game.card import Card, Suit, Rank
from game.bidding_state import Giruda
from game.trick_judge import determine_winner
from game.game_options import GameOptions

S, D, H, C = Suit.SPADE, Suit.DIAMOND, Suit.HEART, Suit.CLUB


def _card(suit, rank):
    return Card(suit, rank)


def _joker():
    return Card.joker()


def test_mighty_wins():
    trick = [_card(H, Rank.ACE), _card(D, Rank.ACE)]
    assert determine_winner(trick, [0, 1], H, Giruda.SPADE, 1, False) == 1


def test_mighty_beats_joker():
    trick = [_joker(), _card(D, Rank.ACE)]
    assert determine_winner(trick, [0, 1], H, Giruda.SPADE, 1, False) == 1


def test_joker_beats_giruda_ace():
    trick = [_card(S, Rank.ACE), _joker()]
    assert determine_winner(trick, [0, 1], S, Giruda.SPADE, 1, False) == 1


def test_joker_nullified_first_trick():
    trick = [_card(H, Rank.TWO), _joker()]
    assert determine_winner(trick, [0, 1], H, Giruda.SPADE, 0, False) == 0


def test_joker_nullified_last_trick():
    trick = [_card(H, Rank.TWO), _joker()]
    assert determine_winner(trick, [0, 1], H, Giruda.SPADE, 9, False) == 0


def test_giruda_beats_lead_suit():
    trick = [_card(H, Rank.ACE), _card(S, Rank.TWO)]
    assert determine_winner(trick, [0, 1], H, Giruda.SPADE, 1, False) == 1


def test_lead_suit_higher_rank_wins():
    trick = [_card(H, Rank.TEN), _card(H, Rank.ACE)]
    assert determine_winner(trick, [0, 1], H, Giruda.SPADE, 1, False) == 1


def test_off_suit_loses():
    trick = [_card(H, Rank.TWO), _card(C, Rank.ACE)]
    assert determine_winner(trick, [0, 1], H, Giruda.SPADE, 1, False) == 0


def test_first_trick_mighty_no_effect():
    opts = GameOptions()
    opts.first_trick_mighty_effect = False
    trick = [_card(H, Rank.ACE), _card(D, Rank.ACE)]
    assert determine_winner(trick, [0, 1], H, Giruda.SPADE, 0, False, opts) == 0


def test_joker_called_joker_with_effect():
    opts = GameOptions()
    opts.joker_called_joker_effect = True
    trick = [_card(C, Rank.THREE), _joker(), _card(C, Rank.ACE)]
    assert determine_winner(trick, [0, 1, 2], C, Giruda.SPADE, 3, True, opts) == 1

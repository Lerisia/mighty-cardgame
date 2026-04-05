from game.card import Card, Suit, Rank
from game.bidding_state import Giruda
from game.bidding_manager import BiddingManager


def _make_hands():
    return [[Card(Suit.SPADE, Rank(2 + j)) for j in range(10)] for _ in range(5)]


def test_initial_state():
    mgr = BiddingManager(5, 0, _make_hands(), 13)
    assert mgr.current_turn == 0
    assert mgr.highest_bid == 0
    assert mgr.is_finished() is False


def test_place_bid():
    mgr = BiddingManager(5, 0, _make_hands(), 13)
    assert mgr.place_bid(0, 13, Giruda.SPADE) is True
    assert mgr.highest_bid == 13
    assert mgr.highest_bidder == 0


def test_bid_must_be_higher():
    mgr = BiddingManager(5, 0, _make_hands(), 13)
    mgr.place_bid(0, 14, Giruda.SPADE)
    for i in range(1, 4):
        mgr.pass_turn(i)
    assert mgr.place_bid(4, 14, Giruda.SPADE) is False
    assert mgr.place_bid(4, 15, Giruda.SPADE) is True


def test_no_giruda_beats_same():
    mgr = BiddingManager(5, 0, _make_hands(), 13)
    mgr.place_bid(0, 14, Giruda.SPADE)
    for i in range(1, 4):
        mgr.pass_turn(i)
    assert mgr.place_bid(4, 14, Giruda.NO_GIRUDA) is True


def test_minimum_bid_enforced():
    mgr = BiddingManager(5, 0, _make_hands(), 13)
    assert mgr.place_bid(0, 12, Giruda.SPADE) is False
    assert mgr.place_bid(0, 13, Giruda.SPADE) is True


def test_bidding_finishes():
    mgr = BiddingManager(5, 0, _make_hands(), 13)
    mgr.place_bid(0, 15, Giruda.SPADE)
    for i in range(1, 5):
        mgr.pass_turn(i)
    assert mgr.is_finished() is True
    assert mgr.get_declarer() == 0


def test_turn_skips_passed():
    mgr = BiddingManager(5, 0, _make_hands(), 13)
    mgr.place_bid(0, 13, Giruda.SPADE)
    mgr.pass_turn(1)
    mgr.pass_turn(2)
    mgr.place_bid(3, 14, Giruda.SPADE)
    assert mgr.current_turn == 4

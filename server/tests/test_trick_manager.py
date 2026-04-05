from game.card import Card, Suit, Rank
from game.bidding_state import Giruda
from game.declarer_phase import FriendCallType
from game.play_state import PlayState, Role
from game.trick_manager import TrickManager
from game.game_options import GameOptions

H, S, D, C = Suit.HEART, Suit.SPADE, Suit.DIAMOND, Suit.CLUB


def _make_states():
    states = []
    for _ in range(5):
        st = PlayState()
        st.hand = [Card(H, Rank(2 + j)) for j in range(10)]
        states.append(st)
    return states


def _make_manager(declarer=0):
    states = _make_states()
    fc = {"type": FriendCallType.NO_FRIEND}
    return TrickManager(states, declarer, Giruda.SPADE, fc)


def test_declarer_leads_first():
    mgr = _make_manager(2)
    assert mgr.current_turn == 2


def test_play_card_advances_turn():
    mgr = _make_manager(0)
    card = mgr.states[0].hand[0]
    mgr.play_card(0, card)
    assert mgr.current_turn == 1


def test_wrong_turn_rejected():
    mgr = _make_manager(0)
    card = mgr.states[1].hand[0]
    assert mgr.play_card(1, card) is False


def test_trick_resolves():
    mgr = _make_manager(0)
    for i in range(5):
        mgr.play_card(i, mgr.states[i].hand[0])
    assert mgr.trick_number == 1
    assert len(mgr.current_trick) == 0


def test_friend_revealed_on_card():
    states = _make_states()
    fc_card = Card(D, Rank.ACE)
    states[2].hand[0] = fc_card
    fc = {"type": FriendCallType.CARD, "card": fc_card}
    mgr = TrickManager(states, 0, Giruda.SPADE, fc)
    mgr.play_card(0, mgr.states[0].hand[0])
    mgr.play_card(1, mgr.states[1].hand[0])
    mgr.play_card(2, fc_card)
    assert mgr.friend_revealed is True
    assert mgr.friend_index == 2


def test_joker_call():
    states = _make_states()
    states[0].hand[0] = Card(C, Rank.THREE)
    fc = {"type": FriendCallType.NO_FRIEND}
    mgr = TrickManager(states, 0, Giruda.SPADE, fc)
    mgr.trick_number = 1
    assert mgr.play_card_with_joker_call(0, states[0].hand[0]) is True
    assert mgr.joker_called is True


def test_joker_call_invalid_first_trick():
    states = _make_states()
    states[0].hand[0] = Card(C, Rank.THREE)
    fc = {"type": FriendCallType.NO_FRIEND}
    mgr = TrickManager(states, 0, Giruda.SPADE, fc)
    assert mgr.play_card_with_joker_call(0, states[0].hand[0]) is False


def test_last_trick_friend():
    opts = GameOptions()
    opts.allow_last_trick_friend = True
    states = []
    for i in range(5):
        st = PlayState()
        st.hand = [Card(H, Rank(2 + i))]
        states.append(st)
    fc = {"type": FriendCallType.NO_FRIEND}
    mgr = TrickManager(states, 0, Giruda.SPADE, fc, opts)
    mgr.trick_number = 9
    for i in range(5):
        mgr.play_card(i, mgr.states[i].hand[0])
    assert mgr.friend_revealed is True
    assert mgr.friend_index == 4


def test_game_over():
    mgr = _make_manager(0)
    assert mgr.is_game_over() is False
    mgr.trick_number = 10
    assert mgr.is_game_over() is True

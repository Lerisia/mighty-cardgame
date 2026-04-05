from game.round_manager import RoundManager, Phase
from game.bidding_state import Giruda
from game.declarer_phase import FriendCallType
from game.game_options import GameOptions


def test_initial_phase():
    rm = RoundManager(5, 0, 13)
    assert rm.phase == Phase.DEAL


def test_deal_moves_to_bidding():
    rm = RoundManager(5, 0, 13)
    rm.do_deal()
    assert rm.phase == Phase.BIDDING
    assert len(rm.bidding_manager.states) == 5
    assert len(rm.kitty) == 3


def test_full_round_flow():
    rm = RoundManager(5, 0, 13)
    rm.do_deal()

    rm.bidding_manager.place_bid(0, 13, Giruda.SPADE)
    for i in range(1, 5):
        rm.bidding_manager.pass_turn(i)
    rm.advance_from_bidding()
    assert rm.phase == Phase.DECLARER

    rm.declarer_phase.skip_first_change()
    rm.declarer_phase.reveal_kitty()
    to_discard = rm.declarer_phase.hand[:3]
    fc = {"type": FriendCallType.NO_FRIEND}
    rm.declarer_phase.finalize(to_discard, fc)
    rm.advance_from_declarer()
    assert rm.phase == Phase.PLAY

    safety = 0
    while not rm.trick_manager.is_game_over() and safety < 200:
        turn = rm.trick_manager.current_turn
        hand = rm.trick_manager.states[turn].hand
        for card in hand:
            if rm.trick_manager.play_card(turn, card):
                break
        safety += 1

    rm.advance_from_play()
    assert rm.phase == Phase.SCORING

    scores = rm.calculate_scores()
    assert rm.phase == Phase.FINISHED
    total = sum(scores.values())
    assert total == 0


def test_options_passed():
    opts = GameOptions()
    opts.min_bid = 11
    rm = RoundManager(5, 0, 13, opts)
    rm.do_deal()
    assert rm.bidding_manager.minimum_bid == 11

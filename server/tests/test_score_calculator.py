from game.score_calculator import calculate
from game.game_options import GameOptions, BackRunMethod


def test_ruling_party_wins_minimum():
    r = calculate(13, 13, 13, False, False)
    assert r["declarer"] == 0
    assert r["friend"] == 0
    assert r["opposition"] == 0


def test_ruling_party_wins_bid_14():
    r = calculate(14, 14, 13, False, False)
    assert r["declarer"] == 4
    assert r["friend"] == 2
    assert r["opposition"] == -2


def test_opposition_wins():
    r = calculate(15, 12, 13, False, False)
    assert r["declarer"] == -6
    assert r["friend"] == -3
    assert r["opposition"] == 3


def test_no_friend_wins():
    r = calculate(14, 14, 13, True, False)
    assert r["declarer"] == 8
    assert r["friend"] == 0
    assert r["opposition"] == -2


def test_run():
    r = calculate(15, 20, 13, False, False)
    base = (15 - 13) * 2 + (20 - 15)
    assert r["declarer"] == base * 2 * 2
    assert r["friend"] == base * 2
    assert r["opposition"] == -base * 2


def test_no_giruda_doubles():
    r = calculate(13, 15, 13, False, True)
    base = (13 - 13) * 2 + (15 - 13)
    assert r["declarer"] == base * 2 * 2


def test_back_run_default():
    r = calculate(13, 10, 13, False, False)
    assert r["back_run"] is True
    assert r["declarer"] == -6 * 2
    assert r["friend"] == -6
    assert r["opposition"] == 6


def test_no_back_run_ruling_11():
    r = calculate(13, 11, 13, False, False)
    assert r["back_run"] is False


def test_back_run_opposition_method():
    opts = GameOptions()
    opts.back_run_method = BackRunMethod.OPPOSITION_GETS_BID_OR_MORE
    r = calculate(15, 3, 13, False, False, opts)
    assert r["back_run"] is True
    assert r["declarer"] == -24 * 2


def test_zero_sum_all_cases():
    for rp in range(21):
        for bid in range(13, 21):
            for nf in [True, False]:
                r = calculate(bid, rp, 13, nf, False)
                if nf:
                    total = r["declarer"] + 4 * r["opposition"]
                else:
                    total = r["declarer"] + r["friend"] + 3 * r["opposition"]
                assert total == 0, f"bid={bid} rp={rp} nf={nf}"

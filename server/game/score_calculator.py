from __future__ import annotations
from .game_options import GameOptions, BackRunMethod

TOTAL_POINTS = 20
BACK_RUN_THRESHOLD = 10


def calculate(bid: int, ruling_points: int, min_bid: int, no_friend: bool,
              no_giruda: bool, options: GameOptions | None = None) -> dict:
    if options is None:
        options = GameOptions()

    declarer_won = ruling_points >= bid
    is_run = ruling_points == TOTAL_POINTS and declarer_won

    multiplier = 1
    if is_run:
        multiplier *= 2
    if no_giruda and declarer_won:
        multiplier *= 2
    if options.bid_20_run_double and bid == TOTAL_POINTS and is_run:
        multiplier *= 2

    if declarer_won:
        base = ((bid - min_bid) * 2 + (ruling_points - bid)) * multiplier
        if no_friend:
            return {**_no_friend_win(base), "back_run": False}
        return {**_friend_win(base), "back_run": False}
    else:
        back_run = _is_back_run(ruling_points, bid, options)
        if back_run:
            multiplier *= 2
        base = (bid - ruling_points) * multiplier
        if no_friend:
            return {**_no_friend_lose(base), "back_run": back_run}
        return {**_friend_lose(base), "back_run": back_run}


def _is_back_run(ruling_points: int, bid: int, options: GameOptions) -> bool:
    opposition_points = TOTAL_POINTS - ruling_points
    if options.back_run_method == BackRunMethod.RULING_PARTY_10_OR_LESS:
        return ruling_points <= BACK_RUN_THRESHOLD
    if options.back_run_method == BackRunMethod.OPPOSITION_GETS_BID_OR_MORE:
        return opposition_points >= bid
    return False


def _friend_win(base: int) -> dict:
    return {"declarer": base * 2, "friend": base, "opposition": -base}


def _friend_lose(base: int) -> dict:
    return {"declarer": -base * 2, "friend": -base, "opposition": base}


def _no_friend_win(base: int) -> dict:
    return {"declarer": base * 4, "friend": 0, "opposition": -base}


def _no_friend_lose(base: int) -> dict:
    return {"declarer": -base * 4, "friend": 0, "opposition": base}

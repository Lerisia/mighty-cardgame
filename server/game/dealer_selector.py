from __future__ import annotations
import random


def first_game(player_count: int) -> int:
    return random.randint(0, player_count - 1)


def next_dealer(ruling_party_won: bool, declarer_index: int, friend_index: int) -> int:
    if ruling_party_won:
        return declarer_index
    if friend_index < 0:
        return declarer_index
    return friend_index

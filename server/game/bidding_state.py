from __future__ import annotations
from enum import IntEnum


class Giruda(IntEnum):
    NONE = 0
    SPADE = 1
    DIAMOND = 2
    HEART = 3
    CLUB = 4
    NO_GIRUDA = 5


MIN_BID = 11
MAX_BID = 20


class BiddingState:
    def __init__(self) -> None:
        self.passed: bool = False
        self.bid_count: int = 0
        self.bid_giruda: int = Giruda.NONE

    def place_bid(self, count: int, giruda: int) -> bool:
        if self.passed:
            return False
        if count < MIN_BID or count > MAX_BID:
            return False
        self.bid_count = count
        self.bid_giruda = giruda
        return True

    def pass_bid(self) -> None:
        self.passed = True

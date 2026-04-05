from __future__ import annotations
from .game_options import GameOptions, DealMissPenalty as DealMissPenaltyMethod


class DealMissPenalty:
    def __init__(self, player_count: int, options: GameOptions | None = None) -> None:
        self.player_count = player_count
        self.options = options or GameOptions()
        self.consecutive_counts = [0] * player_count
        self.pot = 0

    def calculate_penalty(self, dealer_index: int) -> int:
        if self.options.deal_miss_penalty_method == DealMissPenaltyMethod.FIXED:
            return self.options.deal_miss_fixed_penalty
        if self.options.deal_miss_penalty_method == DealMissPenaltyMethod.DOUBLING:
            streak = self.consecutive_counts[dealer_index]
            return self.options.deal_miss_doubling_base * (1 << streak)
        return self.options.deal_miss_fixed_penalty

    def record_deal_miss(self, dealer_index: int) -> None:
        self.pot += self.calculate_penalty(dealer_index)
        self.consecutive_counts[dealer_index] += 1

    def record_game_played(self) -> None:
        self.consecutive_counts = [0] * self.player_count

    def claim_pot(self) -> int:
        amount = self.pot
        self.pot = 0
        return amount

    def next_dealer_after_deal_miss(self, current_dealer: int, deal_miss_player: int) -> int:
        if self.options.deal_miss_dealer_to_declarer:
            return deal_miss_player
        return current_dealer

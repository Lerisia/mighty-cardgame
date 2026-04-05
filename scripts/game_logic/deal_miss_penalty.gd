class_name DealMissPenalty
extends RefCounted

const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")

var player_count: int
var options: GameOptionsScript
var consecutive_counts: Array = []
var pot: int = 0


func _init(p_player_count: int, p_options: GameOptionsScript = null) -> void:
	player_count = p_player_count
	options = p_options if p_options else GameOptionsScript.new()
	for i in range(player_count):
		consecutive_counts.append(0)


func calculate_penalty(dealer_index: int) -> int:
	match options.deal_miss_penalty_method:
		GameOptionsScript.DealMissPenalty.FIXED:
			return options.deal_miss_fixed_penalty
		GameOptionsScript.DealMissPenalty.DOUBLING:
			var streak: int = consecutive_counts[dealer_index]
			return options.deal_miss_doubling_base * (1 << streak)
	return options.deal_miss_fixed_penalty


func record_deal_miss(dealer_index: int) -> void:
	pot += calculate_penalty(dealer_index)
	consecutive_counts[dealer_index] += 1


func record_game_played() -> void:
	for i in range(player_count):
		consecutive_counts[i] = 0


func claim_pot() -> int:
	var amount: int = pot
	pot = 0
	return amount


func next_dealer_after_deal_miss(current_dealer: int, deal_miss_player: int) -> int:
	if options.deal_miss_dealer_to_declarer:
		return deal_miss_player
	return current_dealer

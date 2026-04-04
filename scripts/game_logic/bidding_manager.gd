class_name BiddingManager
extends RefCounted

const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const DealMissScript = preload("res://scripts/game_logic/deal_miss.gd")

var player_count: int
var states: Array = []
var hands: Array = []
var has_acted: Array = []
var current_turn: int
var highest_bid: int = 0
var highest_giruda: int = BiddingStateScript.Giruda.NONE
var highest_bidder: int = -1
var minimum_bid: int
var deal_miss_declared: bool = false
var deal_miss_player: int = -1


func _init(p_player_count: int, dealer_index: int, p_hands: Array, p_minimum_bid: int = 13) -> void:
	player_count = p_player_count
	current_turn = dealer_index
	hands = p_hands
	minimum_bid = p_minimum_bid
	for i in range(player_count):
		states.append(BiddingStateScript.new())
		has_acted.append(false)


func place_bid(player_index: int, count: int, giruda: int) -> bool:
	if player_index != current_turn:
		return false
	if states[player_index].passed:
		return false
	if count < minimum_bid:
		return false
	if not _is_higher_bid(count, giruda):
		return false
	if not states[player_index].place_bid(count, giruda):
		return false
	highest_bid = count
	highest_giruda = giruda
	highest_bidder = player_index
	has_acted[player_index] = true
	_advance_turn()
	return true


func pass_turn(player_index: int) -> bool:
	if player_index != current_turn:
		return false
	if states[player_index].passed:
		return false
	states[player_index].pass_bid()
	has_acted[player_index] = true
	_advance_turn()
	return true


func can_deal_miss(player_index: int) -> bool:
	if has_acted[player_index]:
		return false
	return DealMissScript.can_declare(hands[player_index])


func declare_deal_miss(player_index: int) -> bool:
	if not can_deal_miss(player_index):
		return false
	deal_miss_declared = true
	deal_miss_player = player_index
	return true


func is_finished() -> bool:
	if highest_bidder < 0:
		return false
	var active := 0
	for state in states:
		if not state.passed:
			active += 1
	return active <= 1


func is_last_player_standing() -> bool:
	var active := 0
	for state in states:
		if not state.passed:
			active += 1
	return active == 1


func get_last_standing_player() -> int:
	for i in range(player_count):
		if not states[i].passed:
			return i
	return -1


func get_declarer() -> int:
	return highest_bidder


func _is_higher_bid(count: int, giruda: int) -> bool:
	if highest_bid == 0:
		return true
	if count > highest_bid:
		return true
	if count == highest_bid:
		if giruda == BiddingStateScript.Giruda.NO_GIRUDA and highest_giruda != BiddingStateScript.Giruda.NO_GIRUDA:
			return true
	return false


func _advance_turn() -> void:
	for i in range(player_count - 1):
		current_turn = (current_turn + 1) % player_count
		if not states[current_turn].passed:
			return

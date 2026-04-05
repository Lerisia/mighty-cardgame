class_name DeclarerPhase
extends RefCounted

const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")

var hand: Array
var kitty: Array
var bid: int
var giruda: int
var options: GameOptionsScript

enum FriendCallType { CARD, FIRST_TRICK_WINNER, NO_FRIEND, PLAYER }

var discarded: Array = []
var first_change_used: bool = false
var kitty_revealed: bool = false
var is_finished: bool = false
var friend_call_type: int = -1
var friend_call_card = null
var friend_call_player: int = -1


func _init(p_hand: Array, p_kitty: Array, p_bid: int, p_giruda: int, p_options: GameOptionsScript = null) -> void:
	hand = p_hand.duplicate()
	kitty = p_kitty
	bid = p_bid
	giruda = p_giruda
	options = p_options if p_options else GameOptionsScript.new()


func change_giruda_first(new_giruda: int, new_bid: int) -> bool:
	if first_change_used:
		return false
	if not options.allow_giruda_change_before_kitty:
		return false
	if not _is_valid_change(new_giruda, new_bid, 1):
		return false
	giruda = new_giruda
	bid = new_bid
	first_change_used = true
	return true


func skip_first_change() -> void:
	first_change_used = true


func reveal_kitty() -> void:
	if not first_change_used:
		return
	kitty_revealed = true
	hand.append_array(kitty)


func change_giruda_second(new_giruda: int, new_bid: int) -> bool:
	if not kitty_revealed:
		return false
	if not options.allow_giruda_change_after_kitty:
		return false
	if not _is_valid_change(new_giruda, new_bid, 2):
		return false
	giruda = new_giruda
	bid = new_bid
	return true


func finalize(to_discard: Array, friend_call: Dictionary) -> bool:
	if not kitty_revealed:
		return false
	if to_discard.size() != 3:
		return false
	var call_type: int = friend_call["type"]
	if call_type == FriendCallType.PLAYER and not options.allow_player_friend:
		return false
	for card in to_discard:
		var idx := hand.find(card)
		if idx < 0:
			return false
		hand.remove_at(idx)
	discarded = to_discard
	friend_call_type = call_type
	if friend_call_type == FriendCallType.CARD:
		friend_call_card = friend_call["card"]
	elif friend_call_type == FriendCallType.PLAYER:
		friend_call_player = friend_call["player_index"]
	is_finished = true
	return true


func _is_valid_change(new_giruda: int, new_bid: int, raise_amount: int) -> bool:
	if new_giruda == BiddingStateScript.Giruda.NO_GIRUDA:
		return new_bid >= bid + raise_amount - 1
	return new_bid >= bid + raise_amount

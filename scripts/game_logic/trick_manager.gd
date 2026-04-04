class_name TrickManager
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")
const CardValidatorScript = preload("res://scripts/game_logic/card_validator.gd")

var hands: Array
var player_count: int
var declarer_index: int
var giruda: int
var friend_call: Dictionary

var trick_number: int = 0
var current_turn: int
var current_trick: Array = []
var current_trick_players: Array = []
var lead_suit: int = -1
var last_trick_winner: int = -1

var friend_index: int = -1
var friend_revealed: bool = false


func _init(p_hands: Array, p_declarer: int, p_giruda: int, p_friend_call: Dictionary) -> void:
	hands = p_hands
	player_count = hands.size()
	declarer_index = p_declarer
	giruda = p_giruda
	friend_call = p_friend_call
	current_turn = declarer_index


func play_card(player_index: int, card) -> bool:
	if player_index != current_turn:
		return false
	if not _is_in_hand(player_index, card):
		return false

	var is_lead := current_trick.size() == 0

	if is_lead:
		if not CardValidatorScript.can_lead(card, hands[player_index], giruda, trick_number):
			return false
	else:
		if not CardValidatorScript.can_follow(card, hands[player_index], lead_suit, giruda, false):
			return false

	_remove_from_hand(player_index, card)
	current_trick.append(card)
	current_trick_players.append(player_index)

	if is_lead:
		if not card.is_joker:
			lead_suit = card.suit

	_check_friend_reveal(player_index, card)
	_advance_turn()
	return true


func _check_friend_reveal(player_index: int, card) -> void:
	if friend_revealed:
		return
	if friend_call["type"] != DeclarerPhaseScript.FriendCallType.CARD:
		return
	var fc = friend_call["card"]
	if card.is_joker and fc.is_joker:
		friend_index = player_index
		friend_revealed = true
		return
	if not card.is_joker and not fc.is_joker:
		if card.suit == fc.suit and card.rank == fc.rank:
			friend_index = player_index
			friend_revealed = true


func _is_in_hand(player_index: int, card) -> bool:
	return hands[player_index].has(card)


func _remove_from_hand(player_index: int, card) -> void:
	var idx: int = hands[player_index].find(card)
	if idx >= 0:
		hands[player_index].remove_at(idx)


func _advance_turn() -> void:
	current_turn = (current_turn + 1) % player_count

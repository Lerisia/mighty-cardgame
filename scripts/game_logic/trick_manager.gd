class_name TrickManager
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")
const CardValidatorScript = preload("res://scripts/game_logic/card_validator.gd")
const TrickJudgeScript = preload("res://scripts/game_logic/trick_judge.gd")
const PlayStateScript = preload("res://scripts/game_logic/play_state.gd")

const TOTAL_TRICKS := 10

var states: Array = []
var player_count: int
var declarer_index: int
var giruda: int
var friend_call: Dictionary

var trick_number: int = 0
var current_turn: int
var current_trick: Array = []
var current_trick_players: Array = []
var lead_suit: int = -1
var joker_called: bool = false
var last_trick_winner: int = -1

var friend_index: int = -1
var friend_revealed: bool = false
var face_down_pile: Array = []


func _init(p_states: Array, p_declarer: int, p_giruda: int, p_friend_call: Dictionary) -> void:
	states = p_states
	player_count = states.size()
	declarer_index = p_declarer
	giruda = p_giruda
	friend_call = p_friend_call
	current_turn = declarer_index

	states[declarer_index].role = PlayStateScript.Role.DECLARER

	if friend_call["type"] == DeclarerPhaseScript.FriendCallType.CARD:
		for i in range(player_count):
			if i == declarer_index:
				continue
			for card in states[i].hand:
				if _matches_friend_card(card):
					states[i].is_friend = true
					break
	elif friend_call["type"] == DeclarerPhaseScript.FriendCallType.PLAYER:
		var fi: int = friend_call["player_index"]
		states[fi].is_friend = true


func is_game_over() -> bool:
	return trick_number >= TOTAL_TRICKS


func play_card(player_index: int, card) -> bool:
	if player_index != current_turn:
		return false
	var state = states[player_index]
	if not state.hand.has(card):
		return false

	var is_lead := current_trick.size() == 0

	if is_lead:
		if not CardValidatorScript.can_lead(card, state.hand, giruda, trick_number):
			return false
	else:
		if not CardValidatorScript.can_follow(card, state.hand, lead_suit, giruda, joker_called):
			return false

	state.play_card(card)
	current_trick.append(card)
	current_trick_players.append(player_index)

	if is_lead:
		if not card.is_joker:
			lead_suit = card.suit

	_check_friend_reveal(player_index, card)

	if current_trick.size() == player_count:
		_resolve_trick()
	else:
		_advance_turn()
	return true


func play_card_with_joker_suit(player_index: int, card, designated_suit: int) -> bool:
	if player_index != current_turn:
		return false
	if not card.is_joker:
		return false
	if current_trick.size() != 0:
		return false
	var state = states[player_index]
	if not state.hand.has(card):
		return false

	state.play_card(card)
	current_trick.append(card)
	current_trick_players.append(player_index)
	lead_suit = designated_suit

	_check_friend_reveal(player_index, card)

	if current_trick.size() == player_count:
		_resolve_trick()
	else:
		_advance_turn()
	return true


func play_card_with_joker_call(player_index: int, card) -> bool:
	if player_index != current_turn:
		return false
	if current_trick.size() != 0:
		return false
	if trick_number == 0 or trick_number == 9:
		return false
	if not _is_joker_call_card(card):
		return false

	joker_called = true
	return play_card(player_index, card)


func _is_joker_call_card(card) -> bool:
	if card.is_joker:
		return false
	if giruda == BiddingStateScript.Giruda.CLUB:
		return card.suit == CardScript.Suit.SPADE and card.rank == CardScript.Rank.THREE
	return card.suit == CardScript.Suit.CLUB and card.rank == CardScript.Rank.THREE


func _resolve_trick() -> void:
	var winner: int = TrickJudgeScript.determine_winner(
		current_trick, current_trick_players, lead_suit, giruda, trick_number, joker_called
	)
	last_trick_winner = winner

	if _is_ruling_party(winner):
		face_down_pile.append_array(current_trick)
	else:
		for card in current_trick:
			if card.is_point_card:
				states[winner].point_cards.append(card)
			else:
				face_down_pile.append(card)

	if not friend_revealed and friend_call["type"] == DeclarerPhaseScript.FriendCallType.FIRST_TRICK_WINNER:
		if trick_number == 0 and winner != declarer_index:
			_reveal_friend(winner)

	trick_number += 1
	current_trick = []
	current_trick_players = []
	joker_called = false
	lead_suit = -1
	current_turn = last_trick_winner


func _reveal_friend(player_index: int) -> void:
	friend_index = player_index
	friend_revealed = true
	states[player_index].role = PlayStateScript.Role.FRIEND
	var moved: Array = states[player_index].clear_point_cards()
	face_down_pile.append_array(moved)


func _check_friend_reveal(player_index: int, card) -> void:
	if friend_revealed:
		return
	if friend_call["type"] != DeclarerPhaseScript.FriendCallType.CARD:
		return
	if _matches_friend_card(card):
		_reveal_friend(player_index)


func _matches_friend_card(card) -> bool:
	var fc = friend_call["card"]
	if card.is_joker and fc.is_joker:
		return true
	if not card.is_joker and not fc.is_joker:
		if card.suit == fc.suit and card.rank == fc.rank:
			return true
	return false


func _is_ruling_party(player_index: int) -> bool:
	if player_index == declarer_index:
		return true
	if friend_revealed and player_index == friend_index:
		return true
	return false


func _advance_turn() -> void:
	current_turn = (current_turn + 1) % player_count

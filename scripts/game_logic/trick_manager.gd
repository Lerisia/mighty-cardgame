class_name TrickManager
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")
const CardValidatorScript = preload("res://scripts/game_logic/card_validator.gd")
const TrickJudgeScript = preload("res://scripts/game_logic/trick_judge.gd")

const TOTAL_TRICKS := 10

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
var joker_called: bool = false
var last_trick_winner: int = -1

var friend_index: int = -1
var friend_revealed: bool = false

var player_point_cards: Array = []
var face_down_pile: Array = []


func _init(p_hands: Array, p_declarer: int, p_giruda: int, p_friend_call: Dictionary) -> void:
	hands = p_hands
	player_count = hands.size()
	declarer_index = p_declarer
	giruda = p_giruda
	friend_call = p_friend_call
	current_turn = declarer_index
	for i in range(player_count):
		player_point_cards.append([])


func is_game_over() -> bool:
	return trick_number >= TOTAL_TRICKS


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
		if not CardValidatorScript.can_follow(card, hands[player_index], lead_suit, giruda, joker_called):
			return false

	_remove_from_hand(player_index, card)
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
	if not _is_in_hand(player_index, card):
		return false

	_remove_from_hand(player_index, card)
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
				player_point_cards[winner].append(card)
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


func _is_ruling_party(player_index: int) -> bool:
	if player_index == declarer_index:
		return true
	if friend_revealed and player_index == friend_index:
		return true
	return false


func _move_points_to_face_down(player_index: int) -> void:
	face_down_pile.append_array(player_point_cards[player_index])
	player_point_cards[player_index] = []


func _reveal_friend(player_index: int) -> void:
	friend_index = player_index
	friend_revealed = true
	_move_points_to_face_down(player_index)


func _check_friend_reveal(player_index: int, card) -> void:
	if friend_revealed:
		return
	if friend_call["type"] != DeclarerPhaseScript.FriendCallType.CARD:
		return
	var fc = friend_call["card"]
	if card.is_joker and fc.is_joker:
		_reveal_friend(player_index)
		return
	if not card.is_joker and not fc.is_joker:
		if card.suit == fc.suit and card.rank == fc.rank:
			_reveal_friend(player_index)


func _is_in_hand(player_index: int, card) -> bool:
	return hands[player_index].has(card)


func _remove_from_hand(player_index: int, card) -> void:
	var idx: int = hands[player_index].find(card)
	if idx >= 0:
		hands[player_index].remove_at(idx)


func _advance_turn() -> void:
	current_turn = (current_turn + 1) % player_count

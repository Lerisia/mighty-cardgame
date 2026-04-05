class_name BotManager
extends RefCounted

const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")

var strategy
var player_index: int


func _init(p_strategy, p_player_index: int) -> void:
	strategy = p_strategy
	player_index = p_player_index


func do_bidding_turn(bidding_manager) -> void:
	var state = bidding_manager.states[player_index]
	if state.passed:
		return

	var hand: Array = bidding_manager.hands[player_index]

	if bidding_manager.can_deal_miss(player_index):
		pass

	var result: Dictionary = strategy.decide_bid(
		hand,
		bidding_manager.minimum_bid,
		bidding_manager.highest_bid,
		bidding_manager.highest_giruda,
	)

	if result["pass"]:
		if bidding_manager.is_last_player_standing():
			bidding_manager.place_bid(
				player_index,
				bidding_manager.minimum_bid,
				BiddingStateScript.Giruda.SPADE,
			)
		else:
			bidding_manager.pass_turn(player_index)
	else:
		bidding_manager.place_bid(player_index, result["bid"], result["giruda"])


func do_declarer_phase(declarer_phase) -> void:
	var first_change: Dictionary = strategy.decide_giruda_change(
		declarer_phase.hand, declarer_phase.bid, declarer_phase.giruda, 1
	)
	if first_change["change"]:
		declarer_phase.change_giruda_first(first_change["giruda"], first_change["bid"])
	else:
		declarer_phase.skip_first_change()

	declarer_phase.reveal_kitty()

	var second_change: Dictionary = strategy.decide_giruda_change(
		declarer_phase.hand, declarer_phase.bid, declarer_phase.giruda, 2
	)
	if second_change["change"]:
		declarer_phase.change_giruda_second(second_change["giruda"], second_change["bid"])

	var discard: Array = strategy.decide_discard(declarer_phase.hand, declarer_phase.giruda)
	var friend_call: Dictionary = strategy.decide_friend(declarer_phase.hand, declarer_phase.giruda)

	declarer_phase.finalize(discard, friend_call)


func do_trick_turn(trick_manager) -> void:
	var state = trick_manager.states[player_index]
	var is_lead: bool = trick_manager.current_trick.size() == 0

	if is_lead:
		_do_lead(trick_manager, state)
	else:
		_do_follow(trick_manager, state)


func _do_lead(trick_manager, state) -> void:
	var used_cards: Array = _get_used_cards(trick_manager)

	var should_joker_call: bool = strategy.decide_joker_call(
		state.hand, trick_manager.giruda, trick_manager.trick_number
	)

	if should_joker_call:
		for card in state.hand:
			if trick_manager.play_card_with_joker_call(player_index, card):
				return

	var result: Dictionary = strategy.decide_card_lead(
		state.hand, trick_manager.giruda, trick_manager.trick_number, used_cards
	)
	var card = result["card"]

	if card.is_joker and result.has("joker_suit"):
		trick_manager.play_card_with_joker_suit(player_index, card, result["joker_suit"])
	else:
		trick_manager.play_card(player_index, card)


func _do_follow(trick_manager, state) -> void:
	var used_cards: Array = _get_used_cards(trick_manager)

	var result: Dictionary = strategy.decide_card_follow(
		state.hand, trick_manager.lead_suit, trick_manager.giruda,
		trick_manager.joker_called, used_cards
	)

	trick_manager.play_card(player_index, result["card"])


func _get_used_cards(trick_manager) -> Array:
	var used := [{}, {}, {}, {}]
	for card in trick_manager.current_trick:
		if not card.is_joker:
			var power: int = card.rank - 1
			used[card.suit][power] = true
	return used

class_name CardSelector
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const CardValidatorScript = preload("res://scripts/game_logic/card_validator.gd")
const PenaltyTableScript = preload("res://scripts/ai/penalty_table.gd")


static func select_lead(hand: Array, giruda: int, trick_number: int, used_cards: Array) -> CardScript:
	var best_card = null
	var best_penalty: int = 999999999

	for card in hand:
		if not CardValidatorScript.can_lead(card, hand, giruda, trick_number):
			continue
		var penalty: int = PenaltyTableScript.card_usage_penalty(card, giruda, used_cards)
		if penalty < best_penalty:
			best_penalty = penalty
			best_card = card

	return best_card


static func select_follow(hand: Array, lead_suit: int, giruda: int, joker_called: bool, used_cards: Array) -> CardScript:
	var best_card = null
	var best_penalty: int = 999999999

	for card in hand:
		if not CardValidatorScript.can_follow(card, hand, lead_suit, giruda, joker_called):
			continue
		var penalty: int = PenaltyTableScript.card_usage_penalty(card, giruda, used_cards)
		if penalty < best_penalty:
			best_penalty = penalty
			best_card = card

	return best_card

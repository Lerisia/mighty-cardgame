class_name TrickJudge
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")
const CardValidatorScript = preload("res://scripts/game_logic/card_validator.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")

const LAST_TRICK := 9


static func determine_winner(trick: Array, players: Array, lead_suit: int, giruda: int, trick_number: int, joker_called: bool) -> int:
	var best_index := 0
	var best_score := _card_strength(trick[0], lead_suit, giruda, trick_number, joker_called)

	for i in range(1, trick.size()):
		var score := _card_strength(trick[i], lead_suit, giruda, trick_number, joker_called)
		if score > best_score:
			best_score = score
			best_index = i

	return players[best_index]


static func _card_strength(card, lead_suit: int, giruda: int, trick_number: int, joker_called: bool) -> int:
	if CardValidatorScript.is_mighty(card, giruda):
		return 1000

	if card.is_joker:
		if _is_joker_nullified(trick_number, joker_called):
			return -1
		return 900

	var giruda_suit := _giruda_to_suit(giruda)
	if giruda != BiddingStateScript.Giruda.NO_GIRUDA and card.suit == giruda_suit:
		return 200 + card.rank

	if card.suit == lead_suit:
		return 100 + card.rank

	return 0


static func _is_joker_nullified(trick_number: int, joker_called: bool) -> bool:
	if trick_number == 0 or trick_number == LAST_TRICK:
		return true
	if joker_called:
		return true
	return false


static func _giruda_to_suit(giruda: int) -> int:
	match giruda:
		BiddingStateScript.Giruda.SPADE: return CardScript.Suit.SPADE
		BiddingStateScript.Giruda.DIAMOND: return CardScript.Suit.DIAMOND
		BiddingStateScript.Giruda.HEART: return CardScript.Suit.HEART
		BiddingStateScript.Giruda.CLUB: return CardScript.Suit.CLUB
	return -1

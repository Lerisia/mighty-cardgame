class_name TrickJudge
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")
const CardValidatorScript = preload("res://scripts/game_logic/card_validator.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")

const LAST_TRICK := 9


static func determine_winner(trick: Array, players: Array, lead_suit: int, giruda: int, trick_number: int, joker_called: bool) -> int:
	return determine_winner_with_options(trick, players, lead_suit, giruda, trick_number, joker_called, GameOptionsScript.new())


static func determine_winner_with_options(trick: Array, players: Array, lead_suit: int, giruda: int, trick_number: int, joker_called: bool, options: GameOptionsScript) -> int:
	var best_index := 0
	var best_score := _card_strength(trick[0], lead_suit, giruda, trick_number, joker_called, options)

	for i in range(1, trick.size()):
		var score := _card_strength(trick[i], lead_suit, giruda, trick_number, joker_called, options)
		if score > best_score:
			best_score = score
			best_index = i

	return players[best_index]


static func _card_strength(card, lead_suit: int, giruda: int, trick_number: int, joker_called: bool, options: GameOptionsScript) -> int:
	if CardValidatorScript.is_mighty_with_options(card, giruda, options):
		if _is_mighty_nullified(trick_number, options):
			# Mighty has no special power, treat as normal card
			pass
		else:
			return 1000

	if card.is_joker:
		if _is_joker_nullified(trick_number, joker_called, options):
			return -1
		return 900

	var giruda_suit := _giruda_to_suit(giruda)
	if giruda != BiddingStateScript.Giruda.NO_GIRUDA and card.suit == giruda_suit:
		return 200 + card.rank

	if card.suit == lead_suit:
		return 100 + card.rank

	return 0


static func _is_mighty_nullified(trick_number: int, options: GameOptionsScript) -> bool:
	if trick_number == 0 and not options.first_trick_mighty_effect:
		return true
	if trick_number == LAST_TRICK and not options.last_trick_mighty_effect:
		return true
	return false


static func _is_joker_nullified(trick_number: int, joker_called: bool, options: GameOptionsScript) -> bool:
	if trick_number == 0 and not options.first_trick_joker_effect:
		return true
	if trick_number == LAST_TRICK and not options.last_trick_joker_effect:
		return true
	if joker_called and not options.joker_called_joker_effect:
		return true
	return false


static func _giruda_to_suit(giruda: int) -> int:
	match giruda:
		BiddingStateScript.Giruda.SPADE: return CardScript.Suit.SPADE
		BiddingStateScript.Giruda.DIAMOND: return CardScript.Suit.DIAMOND
		BiddingStateScript.Giruda.HEART: return CardScript.Suit.HEART
		BiddingStateScript.Giruda.CLUB: return CardScript.Suit.CLUB
	return -1

class_name DealMiss
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")
const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")


static func card_score(card: CardScript) -> float:
	return card_score_with_options(card, GameOptionsScript.new())


static func card_score_with_options(card: CardScript, options: GameOptionsScript) -> float:
	if card.is_joker:
		return options.deal_miss_joker_score
	if card.suit == CardScript.Suit.SPADE and card.rank == CardScript.Rank.ACE:
		return options.deal_miss_mighty_score
	if card.rank == CardScript.Rank.TEN:
		return options.deal_miss_ten_score
	if card.is_point_card:
		return options.deal_miss_point_card_score
	return options.deal_miss_non_point_score


static func hand_score(hand: Array) -> float:
	return hand_score_with_options(hand, GameOptionsScript.new())


static func hand_score_with_options(hand: Array, options: GameOptionsScript) -> float:
	var total := 0.0
	for card in hand:
		total += card_score_with_options(card, options)
	return total


static func can_declare(hand: Array) -> bool:
	return can_declare_with_options(hand, GameOptionsScript.new())


static func can_declare_with_options(hand: Array, options: GameOptionsScript) -> bool:
	var score := hand_score_with_options(hand, options)
	match options.deal_miss_threshold_type:
		GameOptionsScript.DealMissThreshold.LESS_THAN:
			return score < options.deal_miss_threshold
		GameOptionsScript.DealMissThreshold.LESS_OR_EQUAL:
			return score <= options.deal_miss_threshold
	return false

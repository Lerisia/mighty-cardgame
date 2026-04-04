class_name DealMiss
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")

const THRESHOLD := 1.0


static func card_score(card: CardScript) -> float:
	if card.is_joker:
		return -1.0
	if card.suit == CardScript.Suit.SPADE and card.rank == CardScript.Rank.ACE:
		return 0.0
	if card.rank == CardScript.Rank.TEN:
		return 0.5
	if card.is_point_card:
		return 1.0
	return 0.0


static func hand_score(hand: Array) -> float:
	var total := 0.0
	for card in hand:
		total += card_score(card)
	return total


static func can_declare(hand: Array) -> bool:
	return hand_score(hand) < THRESHOLD

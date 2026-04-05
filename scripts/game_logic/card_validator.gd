class_name CardValidator
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")

const DEFAULT_MIGHTY_SUIT := CardScript.Suit.SPADE
const DEFAULT_MIGHTY_RANK := CardScript.Rank.ACE


static func is_mighty(card, giruda: int) -> bool:
	var opts = GameOptionsScript.new()
	return is_mighty_with_options(card, giruda, opts)


static func is_mighty_with_options(card, giruda: int, options: GameOptionsScript) -> bool:
	if card.is_joker:
		return false
	if giruda == BiddingStateScript.Giruda.SPADE:
		return card.suit == options.alter_mighty_suit and card.rank == options.alter_mighty_rank
	return card.suit == DEFAULT_MIGHTY_SUIT and card.rank == DEFAULT_MIGHTY_RANK


static func can_lead(card, hand: Array, giruda: int, trick_number: int) -> bool:
	return can_lead_with_options(card, hand, giruda, trick_number, GameOptionsScript.new())


static func can_lead_with_options(card, hand: Array, giruda: int, trick_number: int, options: GameOptionsScript) -> bool:
	if trick_number != 0:
		return true

	if is_mighty_with_options(card, giruda, options):
		return true

	var giruda_suit: int = _giruda_to_suit(giruda)

	if card.is_joker:
		return _hand_only_giruda_and_joker(hand, giruda_suit)

	if giruda != BiddingStateScript.Giruda.NO_GIRUDA and card.suit == giruda_suit:
		if _has_non_giruda_lead_option(hand, giruda_suit, giruda, options):
			return false
		return true

	return true


static func can_follow(card, hand: Array, lead_suit: int, giruda: int, joker_called: bool) -> bool:
	return can_follow_with_options(card, hand, lead_suit, giruda, joker_called, GameOptionsScript.new())


static func can_follow_with_options(card, hand: Array, lead_suit: int, giruda: int, joker_called: bool, options: GameOptionsScript) -> bool:
	if joker_called:
		return _can_follow_joker_call(card, hand, giruda, options)

	if is_mighty_with_options(card, giruda, options):
		return true
	if card.is_joker:
		return true

	var has_lead_suit := _has_suit_in_hand(hand, lead_suit, giruda, options)
	if not has_lead_suit:
		return true

	if not card.is_joker and card.suit == lead_suit:
		return true

	return false


static func _can_follow_joker_call(card, hand: Array, giruda: int, options: GameOptionsScript) -> bool:
	var has_joker := false
	for c in hand:
		if c.is_joker:
			has_joker = true
			break

	if not has_joker:
		return true

	if card.is_joker:
		return true
	if is_mighty_with_options(card, giruda, options):
		return true
	return false


static func _has_suit_in_hand(hand: Array, suit: int, giruda: int, options: GameOptionsScript) -> bool:
	for card in hand:
		if card.is_joker:
			continue
		if is_mighty_with_options(card, giruda, options):
			if card.suit == suit:
				return true
			continue
		if card.suit == suit:
			return true
	return false


static func _has_non_giruda_lead_option(hand: Array, giruda_suit: int, giruda: int, options: GameOptionsScript) -> bool:
	for card in hand:
		if card.is_joker:
			continue
		if is_mighty_with_options(card, giruda, options):
			return true
		if card.suit != giruda_suit:
			return true
	return false


static func _hand_only_giruda_and_joker(hand: Array, giruda_suit: int) -> bool:
	for card in hand:
		if card.is_joker:
			continue
		if card.suit != giruda_suit:
			return false
	return true


static func _giruda_to_suit(giruda: int) -> int:
	match giruda:
		BiddingStateScript.Giruda.SPADE: return CardScript.Suit.SPADE
		BiddingStateScript.Giruda.DIAMOND: return CardScript.Suit.DIAMOND
		BiddingStateScript.Giruda.HEART: return CardScript.Suit.HEART
		BiddingStateScript.Giruda.CLUB: return CardScript.Suit.CLUB
	return -1

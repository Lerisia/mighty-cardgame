class_name CardValidator
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")


static func is_mighty(card, giruda: int) -> bool:
	if card.is_joker:
		return false
	if giruda == BiddingStateScript.Giruda.SPADE:
		return card.suit == CardScript.Suit.DIAMOND and card.rank == CardScript.Rank.ACE
	return card.suit == CardScript.Suit.SPADE and card.rank == CardScript.Rank.ACE


static func can_lead(card, hand: Array, giruda: int, trick_number: int) -> bool:
	if trick_number != 0:
		return true

	var is_card_mighty := is_mighty(card, giruda)
	if is_card_mighty:
		return true

	var giruda_suit: int = _giruda_to_suit(giruda)

	if card.is_joker:
		return _hand_only_giruda_and_joker(hand, giruda_suit)

	if giruda != BiddingStateScript.Giruda.NO_GIRUDA and card.suit == giruda_suit:
		if _has_non_giruda_lead_option(hand, giruda_suit, giruda):
			return false
		return true

	return true


static func can_follow(card, hand: Array, lead_suit: int, giruda: int, joker_called: bool) -> bool:
	if joker_called:
		return _can_follow_joker_call(card, hand, giruda)

	if is_mighty(card, giruda):
		return true
	if card.is_joker:
		return true

	var has_lead_suit := _has_suit_in_hand(hand, lead_suit, giruda)
	if not has_lead_suit:
		return true

	if not card.is_joker and card.suit == lead_suit:
		return true

	return false


static func _can_follow_joker_call(card, hand: Array, giruda: int) -> bool:
	var has_joker := false
	for c in hand:
		if c.is_joker:
			has_joker = true
			break

	if not has_joker:
		return true

	if card.is_joker:
		return true
	if is_mighty(card, giruda):
		return true
	return false


static func _can_follow_normal_suit(card, hand: Array, giruda: int) -> bool:
	return true


static func _has_suit_in_hand(hand: Array, suit: int, giruda: int) -> bool:
	for card in hand:
		if card.is_joker:
			continue
		if is_mighty(card, giruda):
			if card.suit == suit:
				return true
			continue
		if card.suit == suit:
			return true
	return false


static func _has_non_giruda_lead_option(hand: Array, giruda_suit: int, giruda: int) -> bool:
	for card in hand:
		if card.is_joker:
			continue
		if is_mighty(card, giruda):
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

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


static func select_2ma(hand: Array, shown_card, hidden_card) -> int:
	var show_num: int = shown_card.rank
	var hide_num: int = hidden_card.rank

	for i in range(hand.size()):
		var c = hand[i]
		if c.suit == shown_card.suit:
			show_num += 1
		if c.suit == hidden_card.suit:
			hide_num += 1

	if CardValidatorScript.is_mighty(shown_card, BiddingStateScript.Giruda.NONE):
		show_num = 100
	elif shown_card.is_joker:
		show_num = 99
	elif _is_jokercall_any(shown_card) and not _hand_has_joker(hand):
		show_num += 6

	if CardValidatorScript.is_mighty(hidden_card, BiddingStateScript.Giruda.NONE):
		hide_num = 100
	elif hidden_card.is_joker:
		hide_num = 99
	elif _is_jokercall_any(hidden_card) and not _hand_has_joker(hand):
		hide_num += 6

	if show_num > hide_num:
		return 0
	else:
		return 1


static func kill_from_six(hand: Array, giruda: int, failed_so_far: Array) -> CardScript:
	var from_suit: int
	var to_suit: int

	if giruda == BiddingStateScript.Giruda.NO_GIRUDA:
		from_suit = CardScript.Suit.SPADE
		to_suit = CardScript.Suit.CLUB
	else:
		var gs: int = _giruda_to_suit(giruda)
		from_suit = gs
		to_suit = gs

	for s in range(from_suit, to_suit + 1):
		var ace = CardScript.new(s, CardScript.Rank.ACE)
		if not _hand_contains(hand, ace) and not _list_contains(failed_so_far, ace):
			return ace
		for rank_val in range(CardScript.Rank.KING, 2, -1):
			var c = CardScript.new(s, rank_val)
			if not _hand_contains(hand, c) and not _list_contains(failed_so_far, c):
				return c

	return CardScript.new(_giruda_to_suit(giruda), CardScript.Rank.TWO)


static func _is_jokercall_any(card) -> bool:
	if card.is_joker:
		return false
	return card.suit == CardScript.Suit.CLUB and card.rank == CardScript.Rank.THREE


static func _hand_has_joker(hand: Array) -> bool:
	for c in hand:
		if c.is_joker:
			return true
	return false


static func _hand_contains(hand: Array, target) -> bool:
	for card in hand:
		if target.is_joker and card.is_joker:
			return true
		if not target.is_joker and not card.is_joker:
			if card.suit == target.suit and card.rank == target.rank:
				return true
	return false


static func _list_contains(cards: Array, target) -> bool:
	return _hand_contains(cards, target)


static func _giruda_to_suit(giruda: int) -> int:
	match giruda:
		BiddingStateScript.Giruda.SPADE: return CardScript.Suit.SPADE
		BiddingStateScript.Giruda.DIAMOND: return CardScript.Suit.DIAMOND
		BiddingStateScript.Giruda.HEART: return CardScript.Suit.HEART
		BiddingStateScript.Giruda.CLUB: return CardScript.Suit.CLUB
	return -1

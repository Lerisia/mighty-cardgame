class_name PenaltyTable
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const CardValidatorScript = preload("res://scripts/game_logic/card_validator.gd")

const USE_MIGHTY := 2001
const USE_JOKER := 1897
const USE_SAFE_JOKER := 1898
const USE_LAST_JOKER := 2000
const USE_EFFECTIVE_JOKERCALL := 300

const USE_SCORE_GIRUDA := 500
const USE_SCORE_GIRUDA_DIM := -50
const USE_NON_SCORE_GIRUDA := 200
const USE_NON_SCORE_GIRUDA_DIM := -20

const USE_SCORE_NORMAL := 100
const USE_SCORE_NORMAL_DIM := -20
const USE_NON_SCORE_NORMAL := 10
const USE_NON_SCORE_NORMAL_DIM := -1

const DEF_LOST_RATIO := 2000
const DEF_LOST_OVER := 100000000
const ATT_SCORE_PER_POINT := -750


static func card_usage_penalty(card, giruda: int, used_cards: Array = [{}, {}, {}, {}], they_have_joker: bool = false) -> int:
	if CardValidatorScript.is_mighty(card, giruda):
		return USE_MIGHTY

	if card.is_joker:
		if not _is_jokercall_used(giruda, used_cards):
			return USE_JOKER
		elif _is_mighty_used(giruda, used_cards):
			return USE_LAST_JOKER
		else:
			return USE_SAFE_JOKER

	if _is_jokercall(card, giruda):
		if not they_have_joker:
			return USE_EFFECTIVE_JOKERCALL

	var power_num: int = _get_power_num(card)
	var suit_idx: int = card.suit
	var order: int = _count_higher_used(suit_idx, power_num, card.is_point_card, used_cards)

	if _is_giruda_suit(card, giruda):
		if card.is_point_card:
			return USE_SCORE_GIRUDA + USE_SCORE_GIRUDA_DIM * order
		return USE_NON_SCORE_GIRUDA + USE_NON_SCORE_GIRUDA_DIM * order
	else:
		if card.is_point_card:
			return USE_SCORE_NORMAL + USE_SCORE_NORMAL_DIM * order
		return USE_NON_SCORE_NORMAL + USE_NON_SCORE_NORMAL_DIM * order


static func killing_penalty(card, giruda: int, used_cards: Array = [{}, {}, {}, {}], they_have_joker: bool = false) -> int:
	return -card_usage_penalty(card, giruda, used_cards, they_have_joker) / 2


static func defense_lost_penalty(remaining: float, lost_score: float) -> int:
	if lost_score < 0.001:
		return 0
	if remaining < 0.0:
		return -attack_gain_penalty(lost_score)
	if remaining < 0.001 or remaining < lost_score:
		return DEF_LOST_OVER
	return int(DEF_LOST_RATIO * lost_score / remaining)


static func attack_gain_penalty(gain_score: float) -> int:
	if gain_score <= 0:
		return 0
	return int(ATT_SCORE_PER_POINT * gain_score)


static func _get_power_num(card) -> int:
	return card.rank - 1


static func _count_higher_used(suit_idx: int, power: int, is_point: bool, used_cards: Array) -> int:
	var top: int = 13 if is_point else 8
	var order: int = 0
	for i in range(top, power, -1):
		if used_cards[suit_idx].has(i):
			order += 1
	return order


static func _is_jokercall(card, giruda: int) -> bool:
	if card.is_joker:
		return false
	if giruda == BiddingStateScript.Giruda.CLUB:
		return card.suit == CardScript.Suit.SPADE and card.rank == CardScript.Rank.THREE
	return card.suit == CardScript.Suit.CLUB and card.rank == CardScript.Rank.THREE


static func _is_jokercall_used(giruda: int, used_cards: Array) -> bool:
	var jc_suit: int
	var jc_power: int
	if giruda == BiddingStateScript.Giruda.CLUB:
		jc_suit = CardScript.Suit.SPADE
		jc_power = _get_power_num(CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.THREE))
	else:
		jc_suit = CardScript.Suit.CLUB
		jc_power = _get_power_num(CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.THREE))
	return used_cards[jc_suit].has(jc_power)


static func _is_mighty_used(giruda: int, used_cards: Array) -> bool:
	var mighty_suit: int
	var mighty_power: int
	if giruda == BiddingStateScript.Giruda.SPADE:
		mighty_suit = CardScript.Suit.DIAMOND
		mighty_power = _get_power_num(CardScript.new(CardScript.Suit.DIAMOND, CardScript.Rank.ACE))
	else:
		mighty_suit = CardScript.Suit.SPADE
		mighty_power = _get_power_num(CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.ACE))
	return used_cards[mighty_suit].has(mighty_power)


static func _is_giruda_suit(card, giruda: int) -> bool:
	if card.is_joker:
		return false
	if giruda == BiddingStateScript.Giruda.NO_GIRUDA:
		return false
	var giruda_suit: int
	match giruda:
		BiddingStateScript.Giruda.SPADE: giruda_suit = CardScript.Suit.SPADE
		BiddingStateScript.Giruda.DIAMOND: giruda_suit = CardScript.Suit.DIAMOND
		BiddingStateScript.Giruda.HEART: giruda_suit = CardScript.Suit.HEART
		BiddingStateScript.Giruda.CLUB: giruda_suit = CardScript.Suit.CLUB
		_: return false
	return card.suit == giruda_suit


static func mark_used(card, used_cards: Array) -> void:
	if card.is_joker:
		return
	var power: int = _get_power_num(card)
	used_cards[card.suit][power] = true

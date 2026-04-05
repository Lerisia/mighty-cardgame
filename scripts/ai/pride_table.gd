class_name PrideTable
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const CardValidatorScript = preload("res://scripts/game_logic/card_validator.gd")

const BIAS := 1500
const KIRUDA_COUNT_WEIGHT := 300
const KIRUDA_A_WEIGHT := 350
const KIRUDA_K_WEIGHT := 100
const KIRUDA_Q_WEIGHT := 40
const KIRUDA_J_WEIGHT := 30
const ETC_K_WEIGHT := 50
const ETC_Q_WEIGHT := 60
const ETC_J_WEIGHT := 70
const ETC_10_WEIGHT := 80
const EMPTY_WEIGHT := 30
const MIGHTY_WEIGHT := 250
const JOKER_WEIGHT := 250
const JOKERCALL_WEIGHT := 100


static func calc_pride(giruda: int, hand: Array) -> int:
	var pride := 0
	var has_mighty := false
	var has_joker := false
	var has_jokercall := false

	for card in hand:
		if CardValidatorScript.is_mighty(card, giruda):
			has_mighty = true
		if card.is_joker:
			has_joker = true
		if _is_jokercall(card, giruda):
			has_jokercall = true

	if has_mighty:
		pride += MIGHTY_WEIGHT
	if has_joker:
		pride += JOKER_WEIGHT
	if not has_joker and has_jokercall and not has_mighty:
		pride += JOKERCALL_WEIGHT

	var giruda_suit: int = _giruda_to_suit(giruda)

	if giruda != BiddingStateScript.Giruda.NO_GIRUDA:
		var kiruda_count := _count_suit(hand, giruda_suit)
		var ratio: int = 100 * kiruda_count / hand.size()

		if ratio >= 60:
			pride += KIRUDA_COUNT_WEIGHT
		elif ratio >= 40:
			pride += (ratio - 40) * KIRUDA_COUNT_WEIGHT / 20

		if ratio >= 40:
			pride += BIAS

		var d := 0
		if not _has_card(hand, giruda_suit, CardScript.Rank.ACE):
			pride -= KIRUDA_A_WEIGHT
		if not _has_card(hand, giruda_suit, CardScript.Rank.KING):
			d += KIRUDA_K_WEIGHT
			pride -= d
		if not _has_card(hand, giruda_suit, CardScript.Rank.QUEEN):
			d += KIRUDA_Q_WEIGHT
			pride -= d
		if not _has_card(hand, giruda_suit, CardScript.Rank.JACK):
			d += KIRUDA_J_WEIGHT
			pride -= d

	var ndem := _calc_non_kiruda_demerit(hand, giruda)

	if giruda != BiddingStateScript.Giruda.NO_GIRUDA:
		pride += ndem
	else:
		pride += BIAS + KIRUDA_COUNT_WEIGHT
		pride += ndem * 3

	if hand.size() < 10:
		pride = pride * 10 / hand.size()

	return pride


static func pride_to_min_score(pride: int, pride_fac: int, min_bid: int) -> int:
	var real_pride: int

	if pride_fac > 5 and pride < 1850:
		real_pride = pride + (1850 - pride) / (12 - pride_fac)
	elif pride_fac < 5 and pride > 1000:
		real_pride = pride + (pride - 1200) / (pride_fac + 2)
	else:
		real_pride = pride

	var min_score: int = (real_pride + 50) / 100

	if min_score + 1 == min_bid:
		min_score += 1

	min_score = mini(20, maxi(0, min_score))
	return min_score


static func evaluate_best_giruda(hand: Array) -> Dictionary:
	var best_pride := -999999
	var best_giruda: int = BiddingStateScript.Giruda.NONE

	var giruda_options := [
		BiddingStateScript.Giruda.NO_GIRUDA,
		BiddingStateScript.Giruda.SPADE,
		BiddingStateScript.Giruda.DIAMOND,
		BiddingStateScript.Giruda.HEART,
		BiddingStateScript.Giruda.CLUB,
	]

	for g in giruda_options:
		var pride: int = calc_pride(g, hand)
		if pride > best_pride:
			best_pride = pride
			best_giruda = g

	return {"giruda": best_giruda, "pride": best_pride}


static func _calc_non_kiruda_demerit(hand: Array, giruda: int) -> int:
	var giruda_suit: int = _giruda_to_suit(giruda)
	var ndem := 0
	var suit_empty := [true, true, true, true]

	for card in hand:
		if card.is_joker:
			continue
		if CardValidatorScript.is_mighty(card, giruda):
			continue
		if giruda != BiddingStateScript.Giruda.NO_GIRUDA and card.suit == giruda_suit:
			continue
		if card.rank == CardScript.Rank.ACE:
			continue
		if _is_jokercall(card, giruda) and not _hand_has_joker(hand) and not _hand_has_mighty(hand, giruda):
			continue
		if card.rank == CardScript.Rank.KING and CardValidatorScript.is_mighty(CardScript.new(card.suit, CardScript.Rank.ACE), giruda):
			continue

		suit_empty[card.suit] = false

		var power: int = card.rank - 1
		var d: int = 13 - power
		if d == 1:
			ndem -= ETC_K_WEIGHT
		elif d == 2:
			ndem -= ETC_Q_WEIGHT
		elif d == 3:
			ndem -= ETC_J_WEIGHT
		else:
			ndem -= ETC_10_WEIGHT - 4 + d

	for i in range(4):
		if suit_empty[i]:
			ndem += EMPTY_WEIGHT

	var max_friend_assist: int = 2 * (ETC_10_WEIGHT + 12)
	if ndem < -max_friend_assist:
		ndem += max_friend_assist
	elif ndem < 0:
		ndem = 0

	return ndem


static func _count_suit(hand: Array, suit: int) -> int:
	var count := 0
	for card in hand:
		if not card.is_joker and card.suit == suit:
			count += 1
	return count


static func _has_card(hand: Array, suit: int, rank: int) -> bool:
	for card in hand:
		if not card.is_joker and card.suit == suit and card.rank == rank:
			return true
	return false


static func _hand_has_joker(hand: Array) -> bool:
	for card in hand:
		if card.is_joker:
			return true
	return false


static func _hand_has_mighty(hand: Array, giruda: int) -> bool:
	for card in hand:
		if CardValidatorScript.is_mighty(card, giruda):
			return true
	return false


static func _is_jokercall(card, giruda: int) -> bool:
	if card.is_joker:
		return false
	if giruda == BiddingStateScript.Giruda.CLUB:
		return card.suit == CardScript.Suit.SPADE and card.rank == CardScript.Rank.THREE
	return card.suit == CardScript.Suit.CLUB and card.rank == CardScript.Rank.THREE


static func _giruda_to_suit(giruda: int) -> int:
	match giruda:
		BiddingStateScript.Giruda.SPADE: return CardScript.Suit.SPADE
		BiddingStateScript.Giruda.DIAMOND: return CardScript.Suit.DIAMOND
		BiddingStateScript.Giruda.HEART: return CardScript.Suit.HEART
		BiddingStateScript.Giruda.CLUB: return CardScript.Suit.CLUB
	return -1

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
const FRIEND_WEIGHT := 2000


static func calc_pride(giruda: int, hand: Array) -> int:
	var pride: int = 0
	var has_mighty: bool = false
	var has_joker: bool = false

	var mighty_card = _get_mighty(giruda)
	var jokercall_card = _get_jokercall(giruda)

	for card in hand:
		if _card_equals(card, mighty_card):
			has_mighty = true
		if card.is_joker:
			has_joker = true

	if has_mighty:
		pride += MIGHTY_WEIGHT
	if has_joker:
		pride += JOKER_WEIGHT

	if not has_joker and _hand_has_card(hand, jokercall_card) and not has_mighty:
		pride += JOKERCALL_WEIGHT

	var giruda_suit: int = _giruda_to_suit(giruda)

	if giruda != BiddingStateScript.Giruda.NO_GIRUDA:
		var kiruda_count: int = _count_suit(hand, giruda_suit)
		var all_count: int = hand.size()
		var ratio: int = 100 * kiruda_count / all_count

		if ratio >= 60:
			pride += KIRUDA_COUNT_WEIGHT
		elif ratio >= 40:
			pride += (ratio - 40) * KIRUDA_COUNT_WEIGHT / 20

		if ratio >= 40 and _get_kirudable(hand) == giruda_suit:
			pride += BIAS

		var d: int = 0
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

	var refined: Array = _refine(hand, giruda)

	var ndem: int = 0
	var suit_empty: Array = [true, true, true, true]

	for card in refined:
		if card.is_joker:
			continue
		if _card_equals(card, jokercall_card) and not has_joker and not has_mighty:
			continue
		if _card_equals(card, mighty_card):
			continue
		if giruda != BiddingStateScript.Giruda.NO_GIRUDA and card.suit == giruda_suit:
			continue
		if card.rank == CardScript.Rank.ACE:
			continue
		if card.rank == CardScript.Rank.KING and card.suit == mighty_card.suit:
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

	for s in range(4):
		if suit_empty[s]:
			ndem += EMPTY_WEIGHT

	if ndem < -2 * (ETC_10_WEIGHT + 12):
		ndem += 2 * (ETC_10_WEIGHT + 12)
	elif ndem < 0:
		ndem = 0

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
	var best_pride: int = 0
	var best_giruda: int = BiddingStateScript.Giruda.NONE

	var giruda_options: Array = [
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


static func evaluate_best_giruda_13(hand: Array) -> Dictionary:
	var best_pride: int = 0
	var best_giruda: int = BiddingStateScript.Giruda.NONE
	var best_drop: Array = [0, 0, 0]

	for giruda in range(0, 5):
		var giruda_enum: int
		match giruda:
			0: giruda_enum = BiddingStateScript.Giruda.NO_GIRUDA
			1: giruda_enum = BiddingStateScript.Giruda.SPADE
			2: giruda_enum = BiddingStateScript.Giruda.DIAMOND
			3: giruda_enum = BiddingStateScript.Giruda.HEART
			4: giruda_enum = BiddingStateScript.Giruda.CLUB
			_: continue

		for i in range(0, 11):
			if not _is_useless(hand[i], giruda_enum):
				continue
			for j in range(i + 1, 12):
				if not _is_useless(hand[j], giruda_enum):
					continue
				for k in range(j + 1, 13):
					if not _is_useless(hand[k], giruda_enum):
						continue

					var sub_hand: Array = []
					for r in range(13):
						if r == i or r == j or r == k:
							continue
						sub_hand.append(hand[r])

					var pride: int = calc_pride(giruda_enum, sub_hand)
					if pride > best_pride:
						best_pride = pride
						best_giruda = giruda_enum
						best_drop = [i, j, k]

	return {"giruda": best_giruda, "pride": best_pride, "drop": best_drop}


static func _is_useless(card, giruda: int) -> bool:
	var mighty = _get_mighty(giruda)
	if _card_equals(card, mighty):
		return false
	if card.is_joker:
		return false
	if card.rank == CardScript.Rank.ACE:
		return false
	var giruda_suit: int = _giruda_to_suit(giruda)
	if giruda != BiddingStateScript.Giruda.NO_GIRUDA and card.suit == giruda_suit:
		return false
	if card.rank == CardScript.Rank.KING:
		return false
	return true


static func _get_kirudable(hand: Array) -> int:
	var max_suit: int = -1
	var max_sum: int = 0

	for suit in [CardScript.Suit.SPADE, CardScript.Suit.DIAMOND, CardScript.Suit.HEART, CardScript.Suit.CLUB]:
		var s: int = 0
		for card in hand:
			if not card.is_joker and card.suit == suit:
				s += card.rank - 1
		if s > max_sum:
			max_sum = s
			max_suit = suit
	return max_suit


static func _refine(hand: Array, giruda: int) -> Array:
	var sorted_hand: Array = hand.duplicate()
	var giruda_suit: int = _giruda_to_suit(giruda)
	sorted_hand.sort_custom(func(a, b): return _sort_comp(a, b, giruda_suit))

	var result: Array = sorted_hand.duplicate()

	var cur_shape: int = -1
	var cur_score: bool = false
	var cur_pnum: int = -1
	var before_card = null

	var i: int = result.size() - 1
	while i >= 0:
		var c = result[i]

		if c.is_joker:
			i -= 1
			continue

		var c_shape: int = c.suit
		var c_score: bool = c.is_point_card
		var c_pnum: int = c.rank - 1

		if cur_shape != c_shape:
			cur_shape = c_shape
			cur_score = c_score
			cur_pnum = c_pnum
			before_card = c
		elif cur_score != c_score:
			cur_score = c_score
			cur_pnum = c_pnum
			before_card = c
		elif cur_pnum - 1 != c_pnum:
			cur_pnum = c_pnum
			before_card = c
		else:
			result[i] = before_card
			cur_pnum = c_pnum

		i -= 1

	return result


static func _sort_comp(a, b, giruda_suit: int) -> bool:
	if a.is_joker and b.is_joker:
		return false
	if a.is_joker:
		return false
	if b.is_joker:
		return true

	var a_is_kiruda: bool = (giruda_suit >= 0 and a.suit == giruda_suit)
	var b_is_kiruda: bool = (giruda_suit >= 0 and b.suit == giruda_suit)

	if a_is_kiruda and not b_is_kiruda:
		return false
	if not a_is_kiruda and b_is_kiruda:
		return true

	if a.suit != b.suit:
		return a.suit < b.suit

	var a_power: int = a.rank - 1
	var b_power: int = b.rank - 1
	return a_power < b_power


static func _get_mighty(giruda: int):
	if giruda == BiddingStateScript.Giruda.SPADE:
		return CardScript.new(CardScript.Suit.DIAMOND, CardScript.Rank.ACE)
	return CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.ACE)


static func _get_jokercall(giruda: int):
	if giruda == BiddingStateScript.Giruda.CLUB:
		return CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.THREE)
	return CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.THREE)


static func _card_equals(a, b) -> bool:
	if a.is_joker and b.is_joker:
		return true
	if a.is_joker or b.is_joker:
		return false
	return a.suit == b.suit and a.rank == b.rank


static func _hand_has_card(hand: Array, target) -> bool:
	for card in hand:
		if _card_equals(card, target):
			return true
	return false


static func _count_suit(hand: Array, suit: int) -> int:
	var count: int = 0
	for card in hand:
		if not card.is_joker and card.suit == suit:
			count += 1
	return count


static func _has_card(hand: Array, suit: int, rank: int) -> bool:
	for card in hand:
		if not card.is_joker and card.suit == suit and card.rank == rank:
			return true
	return false


static func _giruda_to_suit(giruda: int) -> int:
	match giruda:
		BiddingStateScript.Giruda.SPADE: return CardScript.Suit.SPADE
		BiddingStateScript.Giruda.DIAMOND: return CardScript.Suit.DIAMOND
		BiddingStateScript.Giruda.HEART: return CardScript.Suit.HEART
		BiddingStateScript.Giruda.CLUB: return CardScript.Suit.CLUB
	return -1

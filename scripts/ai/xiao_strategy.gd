class_name XiaoStrategy
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const CardValidatorScript = preload("res://scripts/game_logic/card_validator.gd")
const FriendSelectorScript = preload("res://scripts/ai/friend_selector.gd")
const PenaltyTableScript = preload("res://scripts/ai/penalty_table.gd")
const TrickJudgeScript = preload("res://scripts/game_logic/trick_judge.gd")

const WEIGHT_MIGHTY := 1500
const WEIGHT_JOKER := 300
const WEIGHT_POINT_SUIT := 350
const WEIGHT_KIRUDA_MATCH := 100
const WEIGHT_MISSING_ACE := 40
const WEIGHT_MISSING_KING := 30
const WEIGHT_MISSING_QUEEN := 50
const WEIGHT_MISSING_JACK := 60
const WEIGHT_MISSING_LOWER := 70
const WEIGHT_REMAINING := 80
const WEIGHT_VOID_SUIT := 30
const WEIGHT_RATIO := 100
const WEIGHT_THRESHOLD := 200
const WEIGHT_FACTOR := 100

const FRIEND_ADJ_POSITIVE := 0.3
const FRIEND_ADJ_NEGATIVE := -0.3
const PROB_DECAY := 0.7
const DEFAULT_SUIT_PROB := 0.25
const KIRUDA_SUIT_PROB := 0.5

var declarer_tendency: int = 5

var _player_tracking: Array = []
var _card_status: Dictionary = {}


func decide_bid(hand: Array, min_bid: int, current_highest: int, current_giruda: int) -> Dictionary:
	var best_score: int = -999999
	var best_giruda: int = BiddingStateScript.Giruda.NONE

	var giruda_options := [
		BiddingStateScript.Giruda.NO_GIRUDA,
		BiddingStateScript.Giruda.SPADE,
		BiddingStateScript.Giruda.DIAMOND,
		BiddingStateScript.Giruda.HEART,
		BiddingStateScript.Giruda.CLUB,
	]

	for g in giruda_options:
		var score: int = _calculate_hand_strength(g, hand)
		if score > best_score:
			best_score = score
			best_giruda = g

	var target: int = _score_to_bid(best_score, min_bid)

	if target <= current_highest:
		if best_giruda == BiddingStateScript.Giruda.NO_GIRUDA and current_giruda != BiddingStateScript.Giruda.NO_GIRUDA:
			if target >= current_highest:
				return {"pass": false, "bid": current_highest, "giruda": best_giruda}
		return {"pass": true}

	return {"pass": false, "bid": target, "giruda": best_giruda}


func decide_giruda_change(hand: Array, bid: int, giruda: int, raise_amount: int) -> Dictionary:
	var best_score: int = -999999
	var best_giruda: int = BiddingStateScript.Giruda.NONE

	var giruda_options := [
		BiddingStateScript.Giruda.NO_GIRUDA,
		BiddingStateScript.Giruda.SPADE,
		BiddingStateScript.Giruda.DIAMOND,
		BiddingStateScript.Giruda.HEART,
		BiddingStateScript.Giruda.CLUB,
	]

	for g in giruda_options:
		var score: int = _calculate_hand_strength(g, hand)
		if score > best_score:
			best_score = score
			best_giruda = g

	if best_giruda == giruda:
		return {"change": false}

	var new_bid: int
	if best_giruda == BiddingStateScript.Giruda.NO_GIRUDA:
		new_bid = bid + raise_amount - 1
	else:
		new_bid = bid + raise_amount

	var new_target: int = _score_to_bid(best_score, 11)
	if new_target >= new_bid:
		return {"change": true, "giruda": best_giruda, "bid": new_bid}
	return {"change": false}


func decide_friend(hand: Array, giruda: int) -> Dictionary:
	return FriendSelectorScript.select(hand, giruda)


func decide_card_lead(hand: Array, giruda: int, trick_number: int, used_cards: Array) -> Dictionary:
	var available: Array = _get_leadable(hand, giruda, trick_number)
	if available.is_empty():
		return {"card": hand[0]}

	var giruda_suit: int = _giruda_to_suit(giruda)
	var best_card = null
	var best_ev: float = -999999.0

	for card in available:
		var ev: float = _evaluate_lead_card(card, hand, giruda, giruda_suit, used_cards)
		if ev > best_ev:
			best_ev = ev
			best_card = card

	if best_card == null:
		best_card = available[0]

	var result := {"card": best_card}
	if best_card.is_joker:
		result["joker_suit"] = _pick_joker_lead_suit(hand, giruda)
	return result


func decide_card_follow(hand: Array, lead_suit: int, giruda: int, joker_called: bool, used_cards: Array) -> Dictionary:
	var available: Array = _get_followable(hand, lead_suit, giruda, joker_called)
	if available.is_empty():
		return {"card": hand[0]}

	var best_card = _select_cheapest_follow(available, giruda, used_cards)
	return {"card": best_card}


func decide_joker_call(hand: Array, giruda: int, trick_number: int) -> bool:
	if trick_number == 0 or trick_number == 9:
		return false
	for card in hand:
		if _is_jokercall(card, giruda):
			return true
	return false


func decide_discard(hand: Array, giruda: int) -> Array:
	var scored: Array = []
	for i in range(hand.size()):
		var card = hand[i]
		if CardValidatorScript.is_mighty(card, giruda):
			continue
		if not card.is_joker and _is_giruda_suit_card(card, giruda):
			if card.rank >= CardScript.Rank.KING:
				continue
		var penalty: int = _discard_score(card, giruda)
		scored.append({"index": i, "penalty": penalty})

	scored.sort_custom(func(a, b): return a["penalty"] < b["penalty"])

	var discard := []
	for i in range(mini(3, scored.size())):
		discard.append(hand[scored[i]["index"]])

	if discard.size() < 3:
		for i in range(hand.size()):
			if discard.size() >= 3:
				break
			if not discard.has(hand[i]):
				discard.append(hand[i])

	return discard


func init_probability(player_count: int, my_index: int, declarer_index: int, giruda: int) -> void:
	_player_tracking.clear()
	_card_status.clear()

	for i in range(player_count):
		var tracking := {
			"friend_prob": 0.0,
			"suit_prob": [DEFAULT_SUIT_PROB, DEFAULT_SUIT_PROB, DEFAULT_SUIT_PROB, DEFAULT_SUIT_PROB],
		}
		if i == my_index:
			tracking["friend_prob"] = 0.0
			tracking["suit_prob"] = [0.0, 0.0, 0.0, 0.0]
		elif i == declarer_index:
			tracking["friend_prob"] = 1.0 / (player_count - 1)
			var giruda_suit: int = _giruda_to_suit(giruda)
			for s in range(4):
				if giruda_suit >= 0 and s == giruda_suit:
					tracking["suit_prob"][s] = KIRUDA_SUIT_PROB
				else:
					tracking["suit_prob"][s] = 1.0
		else:
			tracking["friend_prob"] = 1.0 / (player_count - 2) if player_count > 2 else 0.0
			var giruda_suit: int = _giruda_to_suit(giruda)
			for s in range(4):
				if giruda_suit >= 0 and s == giruda_suit:
					tracking["suit_prob"][s] = KIRUDA_SUIT_PROB
				else:
					tracking["suit_prob"][s] = DEFAULT_SUIT_PROB

		_player_tracking.append(tracking)


func update_card_played(player_index: int, card, lead_suit: int) -> void:
	if card.is_joker:
		return

	var card_suit: int = card.suit
	if lead_suit >= 0 and card_suit != lead_suit:
		if player_index < _player_tracking.size():
			_player_tracking[player_index]["suit_prob"][lead_suit] = 0.0

	var card_key: String = _card_key(card)
	_card_status[card_key] = 1


func update_friend_probability(player_index: int, adjustment: float) -> void:
	if player_index < 0 or player_index >= _player_tracking.size():
		return

	var count_others: int = 0
	for i in range(_player_tracking.size()):
		if i != player_index and _player_tracking[i]["friend_prob"] > 0.0:
			count_others += 1

	_player_tracking[player_index]["friend_prob"] = clampf(
		_player_tracking[player_index]["friend_prob"] + adjustment, 0.0, 1.0
	)

	if count_others > 0:
		var redistribute: float = -adjustment / count_others
		for i in range(_player_tracking.size()):
			if i != player_index and _player_tracking[i]["friend_prob"] > 0.0:
				_player_tracking[i]["friend_prob"] = clampf(
					_player_tracking[i]["friend_prob"] + redistribute, 0.0, 1.0
				)


func get_friend_probability(player_index: int) -> float:
	if player_index < 0 or player_index >= _player_tracking.size():
		return 0.0
	return _player_tracking[player_index]["friend_prob"]


func get_suit_probability(player_index: int, suit: int) -> float:
	if player_index < 0 or player_index >= _player_tracking.size():
		return 0.0
	if suit < 0 or suit > 3:
		return 0.0
	return _player_tracking[player_index]["suit_prob"][suit]


func _calculate_hand_strength(giruda: int, hand: Array) -> int:
	var score: int = 0
	var giruda_suit: int = _giruda_to_suit(giruda)
	var has_mighty := false
	var has_joker := false

	for card in hand:
		if CardValidatorScript.is_mighty(card, giruda):
			has_mighty = true
		if card.is_joker:
			has_joker = true

	if has_mighty:
		score += WEIGHT_MIGHTY
	if has_joker:
		score += WEIGHT_JOKER

	if giruda != BiddingStateScript.Giruda.NO_GIRUDA:
		var kiruda_count: int = _count_suit(hand, giruda_suit)
		var ratio: int = 0
		if hand.size() > 0:
			ratio = (kiruda_count * 100) / hand.size()

		if ratio >= 60:
			score += WEIGHT_POINT_SUIT
		elif ratio > 39:
			score += WEIGHT_POINT_SUIT * (ratio - 40) / 20

		if ratio >= 40:
			score += WEIGHT_KIRUDA_MATCH

		var cumulative: int = 0
		if not _has_card(hand, giruda_suit, CardScript.Rank.ACE):
			score -= WEIGHT_MISSING_ACE
		if not _has_card(hand, giruda_suit, CardScript.Rank.KING):
			cumulative += WEIGHT_MISSING_KING
			score -= cumulative
		if not _has_card(hand, giruda_suit, CardScript.Rank.QUEEN):
			cumulative += WEIGHT_MISSING_QUEEN
			score -= cumulative
		if not _has_card(hand, giruda_suit, CardScript.Rank.JACK):
			cumulative += WEIGHT_MISSING_JACK
			score -= cumulative

		for suit_idx in range(4):
			if suit_idx == giruda_suit:
				continue
			if _count_suit(hand, suit_idx) == 0:
				score += WEIGHT_VOID_SUIT
	else:
		score += WEIGHT_KIRUDA_MATCH + WEIGHT_POINT_SUIT
		var void_count: int = 0
		for suit_idx in range(4):
			if _count_suit(hand, suit_idx) == 0:
				void_count += 1
		score += void_count * WEIGHT_VOID_SUIT * 3

	if hand.size() > 0 and hand.size() < 10:
		score = score * 10 / hand.size()

	return score


func _score_to_bid(score: int, min_bid: int) -> int:
	var real_score: int = score
	if declarer_tendency > 5 and score < 1850:
		real_score = score + (1850 - score) / (12 - declarer_tendency)
	elif declarer_tendency < 5 and score > 1000:
		real_score = score + (score - 1200) / (declarer_tendency + 2)

	var bid_level: int = (real_score + 50) / 100
	if bid_level + 1 == min_bid:
		bid_level += 1
	bid_level = clampi(bid_level, 0, 20)
	return bid_level


func _evaluate_lead_card(card, hand: Array, giruda: int, giruda_suit: int, used_cards: Array) -> float:
	if CardValidatorScript.is_mighty(card, giruda):
		return -100.0

	if card.is_joker:
		return 50.0

	var ev: float = 0.0
	var suit: int = card.suit

	if giruda != BiddingStateScript.Giruda.NO_GIRUDA and suit == giruda_suit:
		var is_top: bool = _is_highest_remaining(card, used_cards)
		if is_top:
			ev += 80.0
		else:
			ev -= 20.0
	else:
		var is_top: bool = _is_highest_remaining(card, used_cards)
		if is_top:
			ev += 60.0
		else:
			ev += 10.0

		var suit_count: int = _count_suit(hand, suit)
		if suit_count <= 2:
			ev += 15.0

	if card.is_point_card:
		if _is_highest_remaining(card, used_cards):
			ev += 20.0
		else:
			ev -= 30.0

	return ev


func _select_cheapest_follow(available: Array, giruda: int, used_cards: Array) -> Variant:
	var best_card = null
	var best_priority: int = -999999
	var best_rank: int = 999

	for card in available:
		var priority: int = 0
		var rank_val: int = 0

		if card.is_joker:
			rank_val = 1000
			priority = -500
		elif CardValidatorScript.is_mighty(card, giruda):
			rank_val = 999
			priority = -500
		else:
			rank_val = card.rank

			if card.is_point_card:
				priority = 0
			else:
				priority = 2

			if not _is_giruda_suit_card(card, giruda):
				priority += 4

		if priority > best_priority or (priority == best_priority and rank_val < best_rank):
			best_priority = priority
			best_rank = rank_val
			best_card = card

	return best_card


func _is_highest_remaining(card, used_cards: Array) -> bool:
	if card.is_joker:
		return false
	var suit: int = card.suit
	var power: int = card.rank - 1
	for r in range(12, power, -1):
		if not used_cards[suit].has(r):
			return false
	return true


func _discard_score(card, giruda: int) -> int:
	if card.is_joker:
		return 9999
	if CardValidatorScript.is_mighty(card, giruda):
		return 9999

	var score: int = 0
	if _is_giruda_suit_card(card, giruda):
		score += 500
	if card.is_point_card:
		score += 200
	score += card.rank
	return score


func _get_leadable(hand: Array, giruda: int, trick_number: int) -> Array:
	var result: Array = []
	for card in hand:
		if CardValidatorScript.can_lead(card, hand, giruda, trick_number):
			result.append(card)
	return result


func _get_followable(hand: Array, lead_suit: int, giruda: int, joker_called: bool) -> Array:
	var result: Array = []
	for card in hand:
		if CardValidatorScript.can_follow(card, hand, lead_suit, giruda, joker_called):
			result.append(card)
	return result


func _pick_joker_lead_suit(hand: Array, giruda: int) -> int:
	var suit_counts := [0, 0, 0, 0]
	var giruda_suit: int = _giruda_to_suit(giruda)
	for card in hand:
		if card.is_joker:
			continue
		if CardValidatorScript.is_mighty(card, giruda):
			continue
		if giruda != BiddingStateScript.Giruda.NO_GIRUDA and card.suit == giruda_suit:
			continue
		suit_counts[card.suit] += 1

	var best_suit := 0
	var best_count := -1
	for i in range(4):
		if suit_counts[i] > best_count:
			best_count = suit_counts[i]
			best_suit = i
	return best_suit


func _count_suit(hand: Array, suit: int) -> int:
	var count: int = 0
	for card in hand:
		if not card.is_joker and card.suit == suit:
			count += 1
	return count


func _has_card(hand: Array, suit: int, rank: int) -> bool:
	for card in hand:
		if not card.is_joker and card.suit == suit and card.rank == rank:
			return true
	return false


func _is_jokercall(card, giruda: int) -> bool:
	if card.is_joker:
		return false
	if giruda == BiddingStateScript.Giruda.CLUB:
		return card.suit == CardScript.Suit.SPADE and card.rank == CardScript.Rank.THREE
	return card.suit == CardScript.Suit.CLUB and card.rank == CardScript.Rank.THREE


func _is_giruda_suit_card(card, giruda: int) -> bool:
	if card.is_joker:
		return false
	if giruda == BiddingStateScript.Giruda.NO_GIRUDA:
		return false
	var giruda_suit: int = _giruda_to_suit(giruda)
	return giruda_suit >= 0 and card.suit == giruda_suit


func _giruda_to_suit(giruda: int) -> int:
	match giruda:
		BiddingStateScript.Giruda.SPADE: return CardScript.Suit.SPADE
		BiddingStateScript.Giruda.DIAMOND: return CardScript.Suit.DIAMOND
		BiddingStateScript.Giruda.HEART: return CardScript.Suit.HEART
		BiddingStateScript.Giruda.CLUB: return CardScript.Suit.CLUB
	return -1


func _card_key(card) -> String:
	if card.is_joker:
		return "joker"
	return str(card.suit) + "_" + str(card.rank)

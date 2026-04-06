class_name BSWStrategy
extends RefCounted

const BotStrategyScript = preload("res://scripts/ai/bot_strategy.gd")
const PrideTableScript = preload("res://scripts/ai/pride_table.gd")
const FriendSelectorScript = preload("res://scripts/ai/friend_selector.gd")
const CardSelectorScript = preload("res://scripts/ai/card_selector.gd")
const PenaltyTableScript = preload("res://scripts/ai/penalty_table.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const CardValidatorScript = preload("res://scripts/game_logic/card_validator.gd")

var pride_fac: int = 5


func decide_bid(hand: Array, min_bid: int, current_highest: int, current_giruda: int, kitty: Array = []) -> Dictionary:
	var eval_hand: Array = hand.duplicate()
	if kitty.size() > 0:
		eval_hand.append_array(kitty)

	var eval_result: Dictionary
	if eval_hand.size() == 13:
		eval_result = PrideTableScript.evaluate_best_giruda_13(eval_hand)
	else:
		eval_result = PrideTableScript.evaluate_best_giruda(eval_hand)
	var target: int = PrideTableScript.pride_to_min_score(eval_result["pride"], pride_fac, min_bid)

	if min_bid > target:
		return {"pass": true}

	var bid_value: int
	if current_highest < target and current_highest > 0:
		bid_value = current_highest + 1
	else:
		bid_value = min_bid

	return {"pass": false, "bid": bid_value, "giruda": eval_result["giruda"]}


func decide_giruda_change(hand: Array, bid: int, giruda: int, raise_amount: int) -> Dictionary:
	var eval_result: Dictionary = PrideTableScript.evaluate_best_giruda(hand)
	if eval_result["giruda"] == giruda:
		return {"change": false}

	var new_bid: int
	if eval_result["giruda"] == BiddingStateScript.Giruda.NO_GIRUDA:
		new_bid = bid + raise_amount - 1
	else:
		new_bid = bid + raise_amount

	var new_target: int = PrideTableScript.pride_to_min_score(eval_result["pride"], pride_fac, 11)
	if new_target >= new_bid:
		return {"change": true, "giruda": eval_result["giruda"], "bid": new_bid}
	return {"change": false}


func decide_friend(hand: Array, giruda: int, joker_friend_allowed: bool = true) -> Dictionary:
	return FriendSelectorScript.select(hand, giruda, joker_friend_allowed)


func decide_card_lead(hand: Array, giruda: int, trick_number: int, used_cards: Array) -> Dictionary:
	var card = CardSelectorScript.select_lead(hand, giruda, trick_number, used_cards)
	var result: Dictionary = {"card": card}
	if card.is_joker:
		result["joker_suit"] = _pick_joker_lead_suit(hand, giruda)
	return result


func decide_card_follow(hand: Array, lead_suit: int, giruda: int, joker_called: bool, used_cards: Array) -> Dictionary:
	var card = CardSelectorScript.select_follow(hand, lead_suit, giruda, joker_called, used_cards)
	return {"card": card}


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
		var penalty: int = PenaltyTableScript.card_usage_penalty(hand[i], giruda, [{}, {}, {}, {}])
		scored.append({"index": i, "penalty": penalty})
	scored.sort_custom(func(a, b): return a["penalty"] < b["penalty"])

	var discard: Array = []
	for i in range(mini(3, scored.size())):
		discard.append(hand[scored[i]["index"]])
	return discard


func _pick_joker_lead_suit(hand: Array, giruda: int) -> int:
	var suit_counts: Array = [0, 0, 0, 0]
	var giruda_suit: int = _giruda_to_suit(giruda)
	for card in hand:
		if card.is_joker:
			continue
		if CardValidatorScript.is_mighty(card, giruda):
			continue
		if giruda != BiddingStateScript.Giruda.NO_GIRUDA and card.suit == giruda_suit:
			continue
		suit_counts[card.suit] += 1

	var best_suit: int = 0
	var best_count: int = -1
	for i in range(4):
		if suit_counts[i] > best_count:
			best_count = suit_counts[i]
			best_suit = i
	return best_suit


func _is_jokercall(card, giruda: int) -> bool:
	if card.is_joker:
		return false
	if giruda == BiddingStateScript.Giruda.CLUB:
		return card.suit == CardScript.Suit.SPADE and card.rank == CardScript.Rank.THREE
	return card.suit == CardScript.Suit.CLUB and card.rank == CardScript.Rank.THREE


func _giruda_to_suit(giruda: int) -> int:
	match giruda:
		BiddingStateScript.Giruda.SPADE: return CardScript.Suit.SPADE
		BiddingStateScript.Giruda.DIAMOND: return CardScript.Suit.DIAMOND
		BiddingStateScript.Giruda.HEART: return CardScript.Suit.HEART
		BiddingStateScript.Giruda.CLUB: return CardScript.Suit.CLUB
	return -1

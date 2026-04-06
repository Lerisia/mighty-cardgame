class_name BotStrategy
extends RefCounted


func decide_bid(hand: Array, min_bid: int, current_highest: int, current_giruda: int, kitty: Array = []) -> Dictionary:
	return {"pass": true}


func decide_giruda_change(hand: Array, bid: int, giruda: int, raise_amount: int) -> Dictionary:
	return {"change": false}


func decide_friend(hand: Array, giruda: int) -> Dictionary:
	return {"type": 0}


func decide_card_lead(hand: Array, giruda: int, trick_number: int, used_cards: Array) -> Dictionary:
	return {}


func decide_card_follow(hand: Array, lead_suit: int, giruda: int, joker_called: bool, used_cards: Array) -> Dictionary:
	return {}


func decide_joker_call(hand: Array, giruda: int, trick_number: int) -> bool:
	return false


func decide_discard(hand: Array, giruda: int) -> Array:
	return []

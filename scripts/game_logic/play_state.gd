class_name PlayState
extends RefCounted

enum Role { OPPOSITION, DECLARER, FRIEND }

var role: Role = Role.OPPOSITION
var hand: Array = []
var point_cards: Array = []
var discarded: Array = []
var is_friend: bool = false


func play_card(card) -> bool:
	var idx: int = hand.find(card)
	if idx < 0:
		return false
	hand.remove_at(idx)
	return true


func add_point_cards(cards: Array) -> void:
	for card in cards:
		if card.is_point_card:
			point_cards.append(card)


func get_point_count() -> int:
	return point_cards.size()


func clear_point_cards() -> Array:
	var cards: Array = point_cards.duplicate()
	point_cards = []
	return cards


func set_discarded(cards: Array) -> void:
	discarded = cards

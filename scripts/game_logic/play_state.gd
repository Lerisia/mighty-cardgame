class_name PlayState
extends RefCounted

enum Role { OPPOSITION, DECLARER, FRIEND }

var role: Role = Role.OPPOSITION
var hand: Array = []
var tricks_won: Array = []
var discarded: Array = []
var friend_call_card = null
var friend_reveal_card = null
var friend_revealed: bool = false


func play_card(card) -> bool:
	var idx := hand.find(card)
	if idx < 0:
		return false
	hand.remove_at(idx)
	if friend_reveal_card != null and card == friend_reveal_card:
		friend_revealed = true
	return true


func add_trick(trick: Array) -> void:
	tricks_won.append(trick)


func set_discarded(cards: Array) -> void:
	discarded = cards

class_name Deck
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")

var cards: Array = []


func _init() -> void:
	for suit in CardScript.Suit.values():
		for rank in CardScript.Rank.values():
			cards.append(CardScript.new(suit, rank))
	cards.append(CardScript.create_joker())


func shuffle() -> void:
	cards.shuffle()


func deal(player_count: int) -> Dictionary:
	shuffle()
	var total_deal: int = cards.size() - (cards.size() % player_count)
	var per_player: int = total_deal / player_count
	var hands: Array = []
	for i in range(player_count):
		hands.append(cards.slice(i * per_player, (i + 1) * per_player))
	var kitty: Array = cards.slice(total_deal)
	return { "hands": hands, "kitty": kitty }

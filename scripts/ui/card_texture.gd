class_name CardTexture
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")

const SUIT_NAMES := {
	CardScript.Suit.SPADE: "spades",
	CardScript.Suit.HEART: "hearts",
	CardScript.Suit.DIAMOND: "diamonds",
	CardScript.Suit.CLUB: "clubs",
}

const RANK_NAMES := {
	CardScript.Rank.ACE: "ace",
	CardScript.Rank.TWO: "2",
	CardScript.Rank.THREE: "3",
	CardScript.Rank.FOUR: "4",
	CardScript.Rank.FIVE: "5",
	CardScript.Rank.SIX: "6",
	CardScript.Rank.SEVEN: "7",
	CardScript.Rank.EIGHT: "8",
	CardScript.Rank.NINE: "9",
	CardScript.Rank.TEN: "10",
	CardScript.Rank.JACK: "jack",
	CardScript.Rank.QUEEN: "queen",
	CardScript.Rank.KING: "king",
}

static var _cache: Dictionary = {}


static func get_texture(card) -> Texture2D:
	var path: String = _get_path(card)
	if _cache.has(path):
		return _cache[path]
	var tex: Texture2D = load(path)
	_cache[path] = tex
	return tex


static func get_back_texture() -> Texture2D:
	if _cache.has("back"):
		return _cache["back"]
	var tex: Texture2D = load("res://assets/cards/back.png")
	_cache["back"] = tex
	return tex


static func _get_path(card) -> String:
	if card.is_joker:
		return "res://assets/cards/black_joker.png"
	var rank_name: String = RANK_NAMES[card.rank]
	var suit_name: String = SUIT_NAMES[card.suit]
	return "res://assets/cards/%s_of_%s.png" % [rank_name, suit_name]

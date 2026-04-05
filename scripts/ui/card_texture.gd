class_name CardTexture
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")

const SUIT_MAP := {
	CardScript.Suit.SPADE: 0,
	CardScript.Suit.HEART: 1,
	CardScript.Suit.DIAMOND: 2,
	CardScript.Suit.CLUB: 3,
}

const RANK_MAP := {
	CardScript.Rank.ACE: 1,
	CardScript.Rank.TWO: 2,
	CardScript.Rank.THREE: 3,
	CardScript.Rank.FOUR: 4,
	CardScript.Rank.FIVE: 5,
	CardScript.Rank.SIX: 6,
	CardScript.Rank.SEVEN: 7,
	CardScript.Rank.EIGHT: 8,
	CardScript.Rank.NINE: 9,
	CardScript.Rank.TEN: 10,
	CardScript.Rank.JACK: 11,
	CardScript.Rank.QUEEN: 12,
	CardScript.Rank.KING: 13,
}

static var _cache: Dictionary = {}


static func get_texture(card) -> Texture2D:
	var key: String = _get_key(card)
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = load(_get_path(card))
	_cache[key] = tex
	return tex


static func get_back_texture() -> Texture2D:
	if _cache.has("back"):
		return _cache["back"]
	var tex: Texture2D = load("res://assets/cards/back.png")
	_cache["back"] = tex
	return tex


static func _get_key(card) -> String:
	if card.is_joker:
		return "joker"
	return "%d_%d" % [card.suit, card.rank]


static func _get_path(card) -> String:
	if card.is_joker:
		return "res://assets/cards/4_1.png"
	var suit_num: int = SUIT_MAP[card.suit]
	var rank_num: int = RANK_MAP[card.rank]
	return "res://assets/cards/%d_%d.png" % [suit_num, rank_num]

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


static func get_path(card) -> String:
	if card.is_joker:
		return "res://assets/cards/4_1.svg"
	var suit_num: int = SUIT_MAP[card.suit]
	var rank_num: int = RANK_MAP[card.rank]
	return "res://assets/cards/%d_%d.svg" % [suit_num, rank_num]


static func get_back_path() -> String:
	return "res://assets/cards/back.png"

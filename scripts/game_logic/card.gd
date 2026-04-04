class_name Card
extends Resource

enum Suit { SPADE, DIAMOND, HEART, CLUB }

enum Rank {
	TWO = 2, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, TEN,
	JACK, QUEEN, KING, ACE
}

var suit: Suit
var rank: Rank
var is_joker: bool = false


func _init(p_suit: Suit = Suit.SPADE, p_rank: Rank = Rank.TWO, p_is_joker: bool = false) -> void:
	suit = p_suit
	rank = p_rank
	is_joker = p_is_joker


var is_point_card: bool:
	get:
		if is_joker:
			return false
		return rank >= Rank.TEN


func _to_string() -> String:
	if is_joker:
		return "Joker"
	var suit_str: String = ["S", "D", "H", "C"][suit]
	var rank_str: String
	match rank:
		Rank.JACK: rank_str = "J"
		Rank.QUEEN: rank_str = "Q"
		Rank.KING: rank_str = "K"
		Rank.ACE: rank_str = "A"
		_: rank_str = str(rank)
	return suit_str + rank_str


static func create_joker() -> Card:
	return Card.new(Suit.SPADE, Rank.TWO, true)

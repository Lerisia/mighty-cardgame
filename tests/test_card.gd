extends GdUnitTestSuite

const CardScript = preload("res://scripts/game_logic/card.gd")


func test_suit_has_four_values() -> void:
	assert_int(CardScript.Suit.size()).is_equal(4)


func test_rank_has_thirteen_values() -> void:
	assert_int(CardScript.Rank.size()).is_equal(13)


func test_create_normal_card() -> void:
	var card = CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.ACE)
	assert_int(card.suit).is_equal(CardScript.Suit.SPADE)
	assert_int(card.rank).is_equal(CardScript.Rank.ACE)
	assert_bool(card.is_joker).is_false()


func test_create_joker() -> void:
	var card = CardScript.create_joker()
	assert_bool(card.is_joker).is_true()


func test_all_52_normal_cards_are_unique() -> void:
	var seen := {}
	for suit in CardScript.Suit.values():
		for rank in CardScript.Rank.values():
			var card = CardScript.new(suit, rank)
			var key = card.to_string()
			assert_bool(seen.has(key)).is_false()
			seen[key] = true
	assert_int(seen.size()).is_equal(52)


func test_to_string_normal_cards() -> void:
	var card = CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.ACE)
	assert_str(card.to_string()).is_equal("SA")

	card = CardScript.new(CardScript.Suit.HEART, CardScript.Rank.KING)
	assert_str(card.to_string()).is_equal("HK")

	card = CardScript.new(CardScript.Suit.DIAMOND, CardScript.Rank.TEN)
	assert_str(card.to_string()).is_equal("D10")

	card = CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.TWO)
	assert_str(card.to_string()).is_equal("C2")


func test_to_string_joker() -> void:
	var card = CardScript.create_joker()
	assert_str(card.to_string()).is_equal("Joker")

extends GdUnitTestSuite

const CardSelectorScript = preload("res://scripts/ai/card_selector.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const CardValidatorScript = preload("res://scripts/game_logic/card_validator.gd")

var S := CardScript.Suit.SPADE
var D := CardScript.Suit.DIAMOND
var H := CardScript.Suit.HEART
var C := CardScript.Suit.CLUB


func _card(suit: int, rank: int):
	return CardScript.new(suit, rank)


func test_plays_cheapest_card_on_lead() -> void:
	var hand := [
		_card(H, CardScript.Rank.ACE),
		_card(H, CardScript.Rank.TWO),
		_card(C, CardScript.Rank.THREE),
	]
	var giruda = BiddingStateScript.Giruda.SPADE
	var result = CardSelectorScript.select_lead(hand, giruda, 1, [{}, {}, {}, {}])
	assert_int(result.rank).is_equal(CardScript.Rank.TWO)


func test_follows_suit() -> void:
	var hand := [
		_card(H, CardScript.Rank.ACE),
		_card(C, CardScript.Rank.TWO),
	]
	var giruda = BiddingStateScript.Giruda.SPADE
	var result = CardSelectorScript.select_follow(hand, H, giruda, false, [{}, {}, {}, {}])
	assert_int(result.suit).is_equal(H)


func test_plays_cheapest_when_following() -> void:
	var hand := [
		_card(H, CardScript.Rank.ACE),
		_card(H, CardScript.Rank.TWO),
		_card(H, CardScript.Rank.KING),
	]
	var giruda = BiddingStateScript.Giruda.SPADE
	var result = CardSelectorScript.select_follow(hand, H, giruda, false, [{}, {}, {}, {}])
	assert_int(result.rank).is_equal(CardScript.Rank.TWO)


func test_avoids_mighty_on_lead() -> void:
	var hand := [
		_card(D, CardScript.Rank.ACE),
		_card(H, CardScript.Rank.TWO),
	]
	var giruda = BiddingStateScript.Giruda.SPADE
	var result = CardSelectorScript.select_lead(hand, giruda, 1, [{}, {}, {}, {}])
	assert_int(result.suit).is_equal(H)


func test_avoids_joker_on_lead() -> void:
	var hand := [
		CardScript.create_joker(),
		_card(H, CardScript.Rank.TWO),
	]
	var giruda = BiddingStateScript.Giruda.SPADE
	var result = CardSelectorScript.select_lead(hand, giruda, 1, [{}, {}, {}, {}])
	assert_int(result.suit).is_equal(H)


func test_plays_only_valid_card() -> void:
	var hand := [
		_card(D, CardScript.Rank.ACE),
	]
	var giruda = BiddingStateScript.Giruda.SPADE
	var result = CardSelectorScript.select_lead(hand, giruda, 1, [{}, {}, {}, {}])
	assert_int(result.suit).is_equal(D)


func test_joker_call_forces_joker() -> void:
	var hand := [
		CardScript.create_joker(),
		_card(C, CardScript.Rank.FIVE),
	]
	var giruda = BiddingStateScript.Giruda.SPADE
	var result = CardSelectorScript.select_follow(hand, C, giruda, true, [{}, {}, {}, {}])
	assert_bool(result.is_joker).is_true()

extends GdUnitTestSuite

const PrideTableScript = preload("res://scripts/ai/pride_table.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")

var S := CardScript.Suit.SPADE
var D := CardScript.Suit.DIAMOND
var H := CardScript.Suit.HEART
var C := CardScript.Suit.CLUB


func _card(suit: int, rank: int):
	return CardScript.new(suit, rank)


func test_mighty_bonus() -> void:
	var hand := [_card(D, CardScript.Rank.ACE)]
	for i in range(9):
		hand.append(_card(S, CardScript.Rank.TWO + i))
	var with_mighty = PrideTableScript.calc_pride(BiddingStateScript.Giruda.SPADE, hand)

	var hand2 := [_card(H, CardScript.Rank.TWO)]
	for i in range(9):
		hand2.append(_card(S, CardScript.Rank.TWO + i))
	var without_mighty = PrideTableScript.calc_pride(BiddingStateScript.Giruda.SPADE, hand2)

	assert_int(with_mighty).is_greater(without_mighty)


func test_joker_bonus() -> void:
	var hand := [CardScript.create_joker()]
	for i in range(9):
		hand.append(_card(S, CardScript.Rank.TWO + i))
	var with_joker = PrideTableScript.calc_pride(BiddingStateScript.Giruda.SPADE, hand)

	var hand2 := [_card(H, CardScript.Rank.TWO)]
	for i in range(9):
		hand2.append(_card(S, CardScript.Rank.TWO + i))
	var without_joker = PrideTableScript.calc_pride(BiddingStateScript.Giruda.SPADE, hand2)

	assert_int(with_joker).is_greater(without_joker)


func test_high_kiruda_ratio_better() -> void:
	var hand_high := []
	for i in range(8):
		hand_high.append(_card(S, CardScript.Rank.TWO + i))
	hand_high.append(_card(H, CardScript.Rank.TWO))
	hand_high.append(_card(H, CardScript.Rank.THREE))

	var hand_low := []
	for i in range(4):
		hand_low.append(_card(S, CardScript.Rank.TWO + i))
	for i in range(6):
		hand_low.append(_card(H, CardScript.Rank.TWO + i))

	var pride_high = PrideTableScript.calc_pride(BiddingStateScript.Giruda.SPADE, hand_high)
	var pride_low = PrideTableScript.calc_pride(BiddingStateScript.Giruda.SPADE, hand_low)
	assert_int(pride_high).is_greater(pride_low)


func test_missing_kiruda_ace_penalty() -> void:
	var with_ace := []
	with_ace.append(_card(S, CardScript.Rank.ACE))
	for i in range(9):
		with_ace.append(_card(S, CardScript.Rank.TWO + i))

	var without_ace := []
	without_ace.append(_card(H, CardScript.Rank.TWO))
	for i in range(9):
		without_ace.append(_card(S, CardScript.Rank.TWO + i))

	var pride_with = PrideTableScript.calc_pride(BiddingStateScript.Giruda.SPADE, with_ace)
	var pride_without = PrideTableScript.calc_pride(BiddingStateScript.Giruda.SPADE, without_ace)
	assert_int(pride_with).is_greater(pride_without)


func test_empty_suit_bonus() -> void:
	var hand_void := []
	for i in range(10):
		hand_void.append(_card(S, CardScript.Rank.TWO + i))

	var hand_spread := []
	for i in range(7):
		hand_spread.append(_card(S, CardScript.Rank.TWO + i))
	hand_spread.append(_card(H, CardScript.Rank.TWO))
	hand_spread.append(_card(D, CardScript.Rank.TWO))
	hand_spread.append(_card(C, CardScript.Rank.TWO))

	var pride_void = PrideTableScript.calc_pride(BiddingStateScript.Giruda.SPADE, hand_void)
	var pride_spread = PrideTableScript.calc_pride(BiddingStateScript.Giruda.SPADE, hand_spread)
	assert_int(pride_void).is_greater(pride_spread)


func test_pride_to_min_score_default() -> void:
	assert_int(PrideTableScript.pride_to_min_score(1500, 5, 13)).is_equal(15)
	assert_int(PrideTableScript.pride_to_min_score(1300, 5, 13)).is_equal(13)
	assert_int(PrideTableScript.pride_to_min_score(2000, 5, 13)).is_equal(20)


func test_pride_to_min_score_clamped() -> void:
	assert_int(PrideTableScript.pride_to_min_score(0, 5, 13)).is_equal(0)
	assert_int(PrideTableScript.pride_to_min_score(9999, 5, 13)).is_equal(20)


func test_no_giruda_gets_bias_bonus() -> void:
	var hand := []
	for i in range(10):
		hand.append(_card(S, CardScript.Rank.TWO + i))
	var pride_giruda = PrideTableScript.calc_pride(BiddingStateScript.Giruda.SPADE, hand)
	var pride_no = PrideTableScript.calc_pride(BiddingStateScript.Giruda.NO_GIRUDA, hand)
	assert_int(pride_no).is_greater(0)

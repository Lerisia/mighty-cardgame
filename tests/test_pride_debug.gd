extends GdUnitTestSuite

const PrideTableScript = preload("res://scripts/ai/pride_table.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const DeckScript = preload("res://scripts/game_logic/deck.gd")

var S := CardScript.Suit.SPADE
var D := CardScript.Suit.DIAMOND
var H := CardScript.Suit.HEART
var C := CardScript.Suit.CLUB


func test_average_hand_pride_distribution() -> void:
	var no_giruda_wins := 0
	var targets := []

	for attempt in range(50):
		var deck = DeckScript.new()
		var result: Dictionary = deck.deal(5)
		var hand: Array = result["hands"][0]

		var eval_res: Dictionary = PrideTableScript.evaluate_best_giruda(hand)
		var target: int = PrideTableScript.pride_to_min_score(eval_res["pride"], 5, 13)
		targets.append(target)

		if eval_res["giruda"] == BiddingStateScript.Giruda.NO_GIRUDA:
			no_giruda_wins += 1

		var spade_pride: int = PrideTableScript.calc_pride(BiddingStateScript.Giruda.SPADE, hand)
		var no_pride: int = PrideTableScript.calc_pride(BiddingStateScript.Giruda.NO_GIRUDA, hand)

	# With the fix, no-giruda should win much less often (needs mighty/joker + aces)
	assert_int(no_giruda_wins).is_less(15)


func test_typical_hand_no_giruda_should_lose() -> void:
	var hand := [
		CardScript.new(S, CardScript.Rank.KING),
		CardScript.new(S, CardScript.Rank.EIGHT),
		CardScript.new(S, CardScript.Rank.FIVE),
		CardScript.new(S, CardScript.Rank.THREE),
		CardScript.new(H, CardScript.Rank.QUEEN),
		CardScript.new(H, CardScript.Rank.SEVEN),
		CardScript.new(H, CardScript.Rank.TWO),
		CardScript.new(D, CardScript.Rank.JACK),
		CardScript.new(D, CardScript.Rank.FOUR),
		CardScript.new(C, CardScript.Rank.SIX),
	]

	var spade_pride: int = PrideTableScript.calc_pride(BiddingStateScript.Giruda.SPADE, hand)
	var no_pride: int = PrideTableScript.calc_pride(BiddingStateScript.Giruda.NO_GIRUDA, hand)

	assert_int(spade_pride).is_greater(no_pride)


func test_weak_hand_all_prides_low() -> void:
	var hand := [
		CardScript.new(S, CardScript.Rank.TWO),
		CardScript.new(S, CardScript.Rank.THREE),
		CardScript.new(H, CardScript.Rank.TWO),
		CardScript.new(H, CardScript.Rank.THREE),
		CardScript.new(D, CardScript.Rank.TWO),
		CardScript.new(D, CardScript.Rank.THREE),
		CardScript.new(C, CardScript.Rank.TWO),
		CardScript.new(C, CardScript.Rank.THREE),
		CardScript.new(C, CardScript.Rank.FOUR),
		CardScript.new(C, CardScript.Rank.FIVE),
	]

	for g in [BiddingStateScript.Giruda.SPADE, BiddingStateScript.Giruda.DIAMOND, BiddingStateScript.Giruda.HEART, BiddingStateScript.Giruda.CLUB, BiddingStateScript.Giruda.NO_GIRUDA]:
		var pride: int = PrideTableScript.calc_pride(g, hand)
		var target: int = PrideTableScript.pride_to_min_score(pride, 5, 13)
		assert_int(target).is_less(13)

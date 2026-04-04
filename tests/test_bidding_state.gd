extends GdUnitTestSuite

const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")


func test_initial_state() -> void:
	var state = BiddingStateScript.new()
	assert_bool(state.passed).is_false()
	assert_int(state.bid_count).is_equal(0)
	assert_int(state.bid_giruda).is_equal(BiddingStateScript.Giruda.NONE)


func test_place_bid() -> void:
	var state = BiddingStateScript.new()
	assert_bool(state.place_bid(13, BiddingStateScript.Giruda.SPADE)).is_true()
	assert_int(state.bid_count).is_equal(13)
	assert_int(state.bid_giruda).is_equal(BiddingStateScript.Giruda.SPADE)


func test_bid_minimum_is_1() -> void:
	var state = BiddingStateScript.new()
	assert_bool(state.place_bid(0, BiddingStateScript.Giruda.SPADE)).is_false()
	assert_bool(state.place_bid(1, BiddingStateScript.Giruda.SPADE)).is_true()


func test_bid_maximum_is_20() -> void:
	var state = BiddingStateScript.new()
	assert_bool(state.place_bid(20, BiddingStateScript.Giruda.SPADE)).is_true()
	assert_bool(state.place_bid(21, BiddingStateScript.Giruda.SPADE)).is_false()


func test_no_giruda_bid() -> void:
	var state = BiddingStateScript.new()
	assert_bool(state.place_bid(15, BiddingStateScript.Giruda.NO_GIRUDA)).is_true()
	assert_int(state.bid_giruda).is_equal(BiddingStateScript.Giruda.NO_GIRUDA)


func test_pass() -> void:
	var state = BiddingStateScript.new()
	state.pass_bid()
	assert_bool(state.passed).is_true()


func test_cannot_bid_after_pass() -> void:
	var state = BiddingStateScript.new()
	state.pass_bid()
	assert_bool(state.place_bid(13, BiddingStateScript.Giruda.SPADE)).is_false()


func test_all_giruda_options() -> void:
	assert_int(BiddingStateScript.Giruda.size()).is_equal(6)

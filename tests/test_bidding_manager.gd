extends GdUnitTestSuite

const BiddingManagerScript = preload("res://scripts/game_logic/bidding_manager.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")

var manager: RefCounted


func before_test() -> void:
	var hands := []
	for i in range(5):
		var hand := []
		for j in range(10):
			hand.append(CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.TWO + j))
		hands.append(hand)
	manager = BiddingManagerScript.new(5, 0, hands, 13)


func test_initial_state() -> void:
	assert_int(manager.current_turn).is_equal(0)
	assert_int(manager.highest_bid).is_equal(0)
	assert_bool(manager.is_finished()).is_false()


func test_place_bid() -> void:
	assert_bool(manager.place_bid(0, 13, BiddingStateScript.Giruda.SPADE)).is_true()
	assert_int(manager.highest_bid).is_equal(13)
	assert_int(manager.highest_bidder).is_equal(0)


func test_bid_must_be_higher() -> void:
	manager.place_bid(0, 14, BiddingStateScript.Giruda.SPADE)
	manager.pass_turn(1)
	manager.pass_turn(2)
	manager.pass_turn(3)
	assert_bool(manager.place_bid(4, 14, BiddingStateScript.Giruda.SPADE)).is_false()
	assert_bool(manager.place_bid(4, 15, BiddingStateScript.Giruda.SPADE)).is_true()


func test_no_giruda_beats_same_number() -> void:
	manager.place_bid(0, 14, BiddingStateScript.Giruda.SPADE)
	manager.pass_turn(1)
	manager.pass_turn(2)
	manager.pass_turn(3)
	assert_bool(manager.place_bid(4, 14, BiddingStateScript.Giruda.NO_GIRUDA)).is_true()


func test_same_number_same_type_rejected() -> void:
	manager.place_bid(0, 14, BiddingStateScript.Giruda.SPADE)
	manager.pass_turn(1)
	manager.pass_turn(2)
	manager.pass_turn(3)
	assert_bool(manager.place_bid(4, 14, BiddingStateScript.Giruda.HEART)).is_false()


func test_pass_removes_from_bidding() -> void:
	manager.pass_turn(0)
	assert_bool(manager.states[0].passed).is_true()


func test_cannot_bid_after_pass() -> void:
	manager.pass_turn(0)
	assert_bool(manager.place_bid(0, 13, BiddingStateScript.Giruda.SPADE)).is_false()


func test_last_player_forced_to_bid() -> void:
	manager.pass_turn(0)
	manager.pass_turn(1)
	manager.pass_turn(2)
	manager.pass_turn(3)
	assert_bool(manager.is_last_player_standing()).is_true()
	assert_int(manager.get_last_standing_player()).is_equal(4)


func test_bidding_finishes_when_all_others_pass() -> void:
	manager.place_bid(0, 15, BiddingStateScript.Giruda.SPADE)
	manager.pass_turn(1)
	manager.pass_turn(2)
	manager.pass_turn(3)
	manager.pass_turn(4)
	assert_bool(manager.is_finished()).is_true()
	assert_int(manager.get_declarer()).is_equal(0)


func test_minimum_bid_enforced() -> void:
	assert_bool(manager.place_bid(0, 12, BiddingStateScript.Giruda.SPADE)).is_false()
	assert_bool(manager.place_bid(0, 13, BiddingStateScript.Giruda.SPADE)).is_true()


func test_turn_advances_clockwise() -> void:
	manager.place_bid(0, 13, BiddingStateScript.Giruda.SPADE)
	assert_int(manager.current_turn).is_equal(1)


func test_turn_skips_passed_players() -> void:
	manager.place_bid(0, 13, BiddingStateScript.Giruda.SPADE)
	manager.pass_turn(1)
	manager.pass_turn(2)
	manager.place_bid(3, 14, BiddingStateScript.Giruda.SPADE)
	assert_int(manager.current_turn).is_equal(4)


func _make_weak_hand() -> Array:
	var hand := []
	for i in range(8):
		hand.append(CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.TWO + i))
	hand.append(CardScript.new(CardScript.Suit.DIAMOND, CardScript.Rank.TWO))
	hand.append(CardScript.create_joker())
	return hand


func _make_strong_hand() -> Array:
	var hand := []
	hand.append(CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.ACE))
	hand.append(CardScript.new(CardScript.Suit.HEART, CardScript.Rank.KING))
	hand.append(CardScript.new(CardScript.Suit.HEART, CardScript.Rank.QUEEN))
	for i in range(7):
		hand.append(CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.TWO + i))
	return hand


func test_deal_miss_eligible_player() -> void:
	var hands := []
	hands.append(_make_weak_hand())
	for i in range(4):
		hands.append(_make_strong_hand())
	var mgr = BiddingManagerScript.new(5, 0, hands, 13)
	assert_bool(mgr.can_deal_miss(0)).is_true()


func test_deal_miss_ineligible_player() -> void:
	var hands := []
	hands.append(_make_strong_hand())
	for i in range(4):
		hands.append(_make_weak_hand())
	var mgr = BiddingManagerScript.new(5, 0, hands, 13)
	assert_bool(mgr.can_deal_miss(0)).is_false()


func test_deal_miss_not_allowed_after_bid() -> void:
	var hands := []
	hands.append(_make_weak_hand())
	for i in range(4):
		hands.append(_make_strong_hand())
	var mgr = BiddingManagerScript.new(5, 0, hands, 13)
	mgr.place_bid(0, 13, BiddingStateScript.Giruda.SPADE)
	assert_bool(mgr.can_deal_miss(0)).is_false()


func test_deal_miss_not_allowed_after_pass() -> void:
	var hands := []
	for i in range(5):
		hands.append(_make_weak_hand())
	var mgr = BiddingManagerScript.new(5, 0, hands, 13)
	mgr.pass_turn(0)
	assert_bool(mgr.can_deal_miss(0)).is_false()


func test_declare_deal_miss() -> void:
	var hands := []
	hands.append(_make_weak_hand())
	for i in range(4):
		hands.append(_make_strong_hand())
	var mgr = BiddingManagerScript.new(5, 0, hands, 13)
	assert_bool(mgr.declare_deal_miss(0)).is_true()
	assert_bool(mgr.deal_miss_declared).is_true()
	assert_int(mgr.deal_miss_player).is_equal(0)

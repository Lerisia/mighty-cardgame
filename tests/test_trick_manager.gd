extends GdUnitTestSuite

const TrickManagerScript = preload("res://scripts/game_logic/trick_manager.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")

var S := CardScript.Suit.SPADE
var D := CardScript.Suit.DIAMOND
var H := CardScript.Suit.HEART
var C := CardScript.Suit.CLUB


func _make_hands() -> Array:
	var hands := []
	for i in range(5):
		var hand := []
		for j in range(10):
			hand.append(CardScript.new(H, CardScript.Rank.TWO + j))
		hands.append(hand)
	return hands


func _make_manager(declarer_index: int = 0) -> RefCounted:
	var hands = _make_hands()
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	return TrickManagerScript.new(hands, declarer_index, BiddingStateScript.Giruda.SPADE, friend_call)


func test_declarer_leads_first_trick() -> void:
	var mgr = _make_manager(2)
	assert_int(mgr.current_turn).is_equal(2)


func test_play_card_advances_turn() -> void:
	var mgr = _make_manager(0)
	var card = mgr.hands[0][0]
	mgr.play_card(0, card)
	assert_int(mgr.current_turn).is_equal(1)


func test_wrong_turn_rejected() -> void:
	var mgr = _make_manager(0)
	var card = mgr.hands[1][0]
	assert_bool(mgr.play_card(1, card)).is_false()


func test_hand_shrinks_after_play() -> void:
	var mgr = _make_manager(0)
	assert_int(mgr.hands[0].size()).is_equal(10)
	mgr.play_card(0, mgr.hands[0][0])
	assert_int(mgr.hands[0].size()).is_equal(9)


func test_turn_wraps_around() -> void:
	var mgr = _make_manager(3)
	mgr.play_card(3, mgr.hands[3][0])
	assert_int(mgr.current_turn).is_equal(4)
	mgr.play_card(4, mgr.hands[4][0])
	assert_int(mgr.current_turn).is_equal(0)


# --- Card validation ---

func test_first_trick_cannot_lead_giruda() -> void:
	var hands = _make_hands()
	hands[0][0] = CardScript.new(S, CardScript.Rank.FIVE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	assert_bool(mgr.play_card(0, hands[0][0])).is_false()


func test_lead_suit_set_by_first_card() -> void:
	var mgr = _make_manager(0)
	var card = mgr.hands[0][0]
	mgr.play_card(0, card)
	assert_int(mgr.lead_suit).is_equal(H)


func test_must_follow_suit() -> void:
	var hands = _make_hands()
	hands[1][0] = CardScript.new(C, CardScript.Rank.ACE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.play_card(0, mgr.hands[0][0])
	assert_bool(mgr.play_card(1, hands[1][0])).is_false()
	assert_bool(mgr.play_card(1, mgr.hands[1][1])).is_true()


# --- Friend reveal on card play ---

func test_friend_revealed_on_card_play() -> void:
	var hands = _make_hands()
	var friend_card = CardScript.new(D, CardScript.Rank.ACE)
	hands[2][0] = friend_card
	var friend_call := {
		"type": DeclarerPhaseScript.FriendCallType.CARD,
		"card": friend_card,
	}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	assert_bool(mgr.friend_revealed).is_false()
	mgr.play_card(0, mgr.hands[0][0])
	mgr.play_card(1, mgr.hands[1][0])
	mgr.play_card(2, friend_card)
	assert_bool(mgr.friend_revealed).is_true()
	assert_int(mgr.friend_index).is_equal(2)


func test_friend_not_revealed_by_other_card() -> void:
	var hands = _make_hands()
	var friend_card = CardScript.new(D, CardScript.Rank.ACE)
	var friend_call := {
		"type": DeclarerPhaseScript.FriendCallType.CARD,
		"card": friend_card,
	}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.play_card(0, mgr.hands[0][0])
	assert_bool(mgr.friend_revealed).is_false()


func test_no_friend_never_reveals() -> void:
	var mgr = _make_manager(0)
	mgr.play_card(0, mgr.hands[0][0])
	mgr.play_card(1, mgr.hands[1][0])
	mgr.play_card(2, mgr.hands[2][0])
	mgr.play_card(3, mgr.hands[3][0])
	mgr.play_card(4, mgr.hands[4][0])
	assert_bool(mgr.friend_revealed).is_false()

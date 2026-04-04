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


# --- Joker lead with suit designation ---

func test_joker_lead_sets_designated_suit() -> void:
	var hands = _make_hands()
	hands[0][0] = CardScript.create_joker()
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	assert_bool(mgr.play_card_with_joker_suit(0, hands[0][0], C)).is_true()
	assert_int(mgr.lead_suit).is_equal(C)


func test_joker_lead_non_joker_rejected() -> void:
	var mgr = _make_manager(0)
	assert_bool(mgr.play_card_with_joker_suit(0, mgr.hands[0][0], C)).is_false()


func test_joker_lead_not_on_lead_rejected() -> void:
	var hands = _make_hands()
	hands[1][0] = CardScript.create_joker()
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	mgr.play_card(0, mgr.hands[0][0])
	assert_bool(mgr.play_card_with_joker_suit(1, hands[1][0], C)).is_false()


# --- Joker call ---

func test_joker_call_sets_flag() -> void:
	var hands = _make_hands()
	hands[0][0] = CardScript.new(C, CardScript.Rank.THREE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	assert_bool(mgr.play_card_with_joker_call(0, hands[0][0])).is_true()
	assert_bool(mgr.joker_called).is_true()
	assert_int(mgr.lead_suit).is_equal(C)


func test_joker_call_invalid_on_first_trick() -> void:
	var hands = _make_hands()
	hands[0][0] = CardScript.new(C, CardScript.Rank.THREE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	assert_bool(mgr.play_card_with_joker_call(0, hands[0][0])).is_false()


func test_joker_call_invalid_on_last_trick() -> void:
	var hands = _make_hands()
	hands[0][0] = CardScript.new(C, CardScript.Rank.THREE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 9
	assert_bool(mgr.play_card_with_joker_call(0, hands[0][0])).is_false()


func test_joker_call_wrong_card_rejected() -> void:
	var hands = _make_hands()
	hands[0][0] = CardScript.new(C, CardScript.Rank.FOUR)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	assert_bool(mgr.play_card_with_joker_call(0, hands[0][0])).is_false()


func test_joker_call_spade3_when_club_giruda() -> void:
	var hands = _make_hands()
	hands[0][0] = CardScript.new(S, CardScript.Rank.THREE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.CLUB, friend_call)
	mgr.trick_number = 1
	assert_bool(mgr.play_card_with_joker_call(0, hands[0][0])).is_true()


func test_joker_call_forces_joker_on_follow() -> void:
	var hands = _make_hands()
	hands[0][0] = CardScript.new(C, CardScript.Rank.THREE)
	hands[1][0] = CardScript.create_joker()
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	mgr.play_card_with_joker_call(0, hands[0][0])
	assert_bool(mgr.play_card(1, mgr.hands[1][1])).is_false()
	assert_bool(mgr.play_card(1, hands[1][0])).is_true()


# --- Trick resolution ---

func test_trick_resolves_after_five_cards() -> void:
	var mgr = _make_manager(0)
	for i in range(5):
		mgr.play_card(i, mgr.hands[i][0])
	assert_int(mgr.trick_number).is_equal(1)
	assert_int(mgr.current_trick.size()).is_equal(0)
	assert_int(mgr.lead_suit).is_equal(-1)
	assert_bool(mgr.joker_called).is_false()


func test_trick_winner_leads_next() -> void:
	var hands = _make_hands()
	hands[3][0] = CardScript.new(H, CardScript.Rank.ACE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	for i in range(5):
		mgr.play_card(i, mgr.hands[i][0])
	assert_int(mgr.last_trick_winner).is_equal(3)
	assert_int(mgr.current_turn).is_equal(3)


func test_opposition_winner_gets_point_cards() -> void:
	var hands = _make_hands()
	hands[0][0] = CardScript.new(H, CardScript.Rank.ACE)
	hands[2][0] = CardScript.new(H, CardScript.Rank.KING)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(hands, 1, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	mgr.current_turn = 0
	for i in range(5):
		mgr.play_card(i, mgr.hands[i][0])
	assert_int(mgr.player_point_cards[0].size()).is_greater(0)


func test_declarer_winner_cards_go_face_down() -> void:
	var hands = _make_hands()
	hands[0][0] = CardScript.new(H, CardScript.Rank.ACE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	for i in range(5):
		mgr.play_card(i, mgr.hands[i][0])
	assert_int(mgr.player_point_cards[0].size()).is_equal(0)
	assert_int(mgr.face_down_pile.size()).is_equal(5)


func test_game_over_after_ten_tricks() -> void:
	var mgr = _make_manager(0)
	assert_bool(mgr.is_game_over()).is_false()
	mgr.trick_number = 10
	assert_bool(mgr.is_game_over()).is_true()


func test_first_trick_winner_friend() -> void:
	var hands = _make_hands()
	hands[3][0] = CardScript.new(H, CardScript.Rank.ACE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.FIRST_TRICK_WINNER}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	for i in range(5):
		mgr.play_card(i, mgr.hands[i][0])
	assert_bool(mgr.friend_revealed).is_true()
	assert_int(mgr.friend_index).is_equal(3)


func test_first_trick_winner_declarer_no_friend() -> void:
	var hands = _make_hands()
	hands[0][0] = CardScript.new(H, CardScript.Rank.ACE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.FIRST_TRICK_WINNER}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	for i in range(5):
		mgr.play_card(i, mgr.hands[i][0])
	assert_bool(mgr.friend_revealed).is_false()


func test_friend_reveal_moves_points_to_face_down() -> void:
	var hands = _make_hands()
	hands[2][0] = CardScript.new(H, CardScript.Rank.ACE)
	var friend_card = CardScript.new(D, CardScript.Rank.ACE)
	hands[2][1] = friend_card
	var friend_call := {
		"type": DeclarerPhaseScript.FriendCallType.CARD,
		"card": friend_card,
	}
	var mgr = TrickManagerScript.new(hands, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	mgr.current_turn = 2
	for i in range(5):
		var pi: int = (2 + i) % 5
		mgr.play_card(pi, mgr.hands[pi][0])
	assert_int(mgr.player_point_cards[2].size()).is_greater(0)
	mgr.current_turn = 2
	mgr.play_card(2, friend_card)
	assert_bool(mgr.friend_revealed).is_true()
	assert_int(mgr.player_point_cards[2].size()).is_equal(0)

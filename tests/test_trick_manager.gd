extends GdUnitTestSuite

const TrickManagerScript = preload("res://scripts/game_logic/trick_manager.gd")
const PlayStateScript = preload("res://scripts/game_logic/play_state.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")
const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")

var S := CardScript.Suit.SPADE
var D := CardScript.Suit.DIAMOND
var H := CardScript.Suit.HEART
var C := CardScript.Suit.CLUB


func _make_states() -> Array:
	var states := []
	for i in range(5):
		var st = PlayStateScript.new()
		for j in range(10):
			st.hand.append(CardScript.new(H, CardScript.Rank.TWO + j))
		states.append(st)
	return states


func _make_manager(declarer_index: int = 0) -> RefCounted:
	var states = _make_states()
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	return TrickManagerScript.new(states, declarer_index, BiddingStateScript.Giruda.SPADE, friend_call)


# --- Turn management ---

func test_declarer_leads_first_trick() -> void:
	var mgr = _make_manager(2)
	assert_int(mgr.current_turn).is_equal(2)


func test_play_card_advances_turn() -> void:
	var mgr = _make_manager(0)
	var card = mgr.states[0].hand[0]
	mgr.play_card(0, card)
	assert_int(mgr.current_turn).is_equal(1)


func test_wrong_turn_rejected() -> void:
	var mgr = _make_manager(0)
	var card = mgr.states[1].hand[0]
	assert_bool(mgr.play_card(1, card)).is_false()


func test_hand_shrinks_after_play() -> void:
	var mgr = _make_manager(0)
	assert_int(mgr.states[0].hand.size()).is_equal(10)
	mgr.play_card(0, mgr.states[0].hand[0])
	assert_int(mgr.states[0].hand.size()).is_equal(9)


func test_turn_wraps_around() -> void:
	var mgr = _make_manager(3)
	mgr.play_card(3, mgr.states[3].hand[0])
	assert_int(mgr.current_turn).is_equal(4)
	mgr.play_card(4, mgr.states[4].hand[0])
	assert_int(mgr.current_turn).is_equal(0)


# --- Card validation ---

func test_first_trick_cannot_lead_giruda() -> void:
	var states = _make_states()
	states[0].hand[0] = CardScript.new(S, CardScript.Rank.FIVE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	assert_bool(mgr.play_card(0, states[0].hand[0])).is_false()


func test_lead_suit_set_by_first_card() -> void:
	var mgr = _make_manager(0)
	mgr.play_card(0, mgr.states[0].hand[0])
	assert_int(mgr.lead_suit).is_equal(H)


func test_must_follow_suit() -> void:
	var states = _make_states()
	states[1].hand[0] = CardScript.new(C, CardScript.Rank.ACE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.play_card(0, mgr.states[0].hand[0])
	assert_bool(mgr.play_card(1, states[1].hand[0])).is_false()
	assert_bool(mgr.play_card(1, mgr.states[1].hand[1])).is_true()


# --- Friend reveal on card play ---

func test_friend_revealed_on_card_play() -> void:
	var states = _make_states()
	var friend_card = CardScript.new(D, CardScript.Rank.ACE)
	states[2].hand[0] = friend_card
	var friend_call := {
		"type": DeclarerPhaseScript.FriendCallType.CARD,
		"card": friend_card,
	}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	assert_bool(mgr.friend_revealed).is_false()
	mgr.play_card(0, mgr.states[0].hand[0])
	mgr.play_card(1, mgr.states[1].hand[0])
	mgr.play_card(2, friend_card)
	assert_bool(mgr.friend_revealed).is_true()
	assert_int(mgr.friend_index).is_equal(2)
	assert_int(mgr.states[2].role).is_equal(PlayStateScript.Role.FRIEND)


func test_friend_not_revealed_by_other_card() -> void:
	var states = _make_states()
	var friend_card = CardScript.new(D, CardScript.Rank.ACE)
	var friend_call := {
		"type": DeclarerPhaseScript.FriendCallType.CARD,
		"card": friend_card,
	}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.play_card(0, mgr.states[0].hand[0])
	assert_bool(mgr.friend_revealed).is_false()


func test_no_friend_never_reveals() -> void:
	var mgr = _make_manager(0)
	for i in range(5):
		mgr.play_card(i, mgr.states[i].hand[0])
	assert_bool(mgr.friend_revealed).is_false()


# --- is_friend set on init ---

func test_is_friend_set_for_card_friend() -> void:
	var states = _make_states()
	var friend_card = CardScript.new(D, CardScript.Rank.ACE)
	states[3].hand[0] = friend_card
	var friend_call := {
		"type": DeclarerPhaseScript.FriendCallType.CARD,
		"card": friend_card,
	}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	assert_bool(mgr.states[3].is_friend).is_true()
	assert_bool(mgr.states[0].is_friend).is_false()
	assert_bool(mgr.states[1].is_friend).is_false()


func test_declarer_role_set_on_init() -> void:
	var mgr = _make_manager(2)
	assert_int(mgr.states[2].role).is_equal(PlayStateScript.Role.DECLARER)


# --- Joker lead with suit designation ---

func test_joker_lead_sets_designated_suit() -> void:
	var states = _make_states()
	states[0].hand[0] = CardScript.create_joker()
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	assert_bool(mgr.play_card_with_joker_suit(0, states[0].hand[0], C)).is_true()
	assert_int(mgr.lead_suit).is_equal(C)


func test_joker_lead_non_joker_rejected() -> void:
	var mgr = _make_manager(0)
	assert_bool(mgr.play_card_with_joker_suit(0, mgr.states[0].hand[0], C)).is_false()


func test_joker_lead_not_on_lead_rejected() -> void:
	var states = _make_states()
	states[1].hand[0] = CardScript.create_joker()
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	mgr.play_card(0, mgr.states[0].hand[0])
	assert_bool(mgr.play_card_with_joker_suit(1, states[1].hand[0], C)).is_false()


# --- Joker call ---

func test_joker_call_sets_flag() -> void:
	var states = _make_states()
	states[0].hand[0] = CardScript.new(C, CardScript.Rank.THREE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	assert_bool(mgr.play_card_with_joker_call(0, states[0].hand[0])).is_true()
	assert_bool(mgr.joker_called).is_true()
	assert_int(mgr.lead_suit).is_equal(C)


func test_joker_call_invalid_on_first_trick() -> void:
	var states = _make_states()
	states[0].hand[0] = CardScript.new(C, CardScript.Rank.THREE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	assert_bool(mgr.play_card_with_joker_call(0, states[0].hand[0])).is_false()


func test_joker_call_invalid_on_last_trick() -> void:
	var states = _make_states()
	states[0].hand[0] = CardScript.new(C, CardScript.Rank.THREE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 9
	assert_bool(mgr.play_card_with_joker_call(0, states[0].hand[0])).is_false()


func test_joker_call_wrong_card_rejected() -> void:
	var states = _make_states()
	states[0].hand[0] = CardScript.new(C, CardScript.Rank.FOUR)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	assert_bool(mgr.play_card_with_joker_call(0, states[0].hand[0])).is_false()


func test_joker_call_spade3_when_club_giruda() -> void:
	var states = _make_states()
	states[0].hand[0] = CardScript.new(S, CardScript.Rank.THREE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.CLUB, friend_call)
	mgr.trick_number = 1
	assert_bool(mgr.play_card_with_joker_call(0, states[0].hand[0])).is_true()


func test_joker_call_forces_joker_on_follow() -> void:
	var states = _make_states()
	states[0].hand[0] = CardScript.new(C, CardScript.Rank.THREE)
	states[1].hand[0] = CardScript.create_joker()
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	mgr.play_card_with_joker_call(0, states[0].hand[0])
	assert_bool(mgr.play_card(1, mgr.states[1].hand[1])).is_false()
	assert_bool(mgr.play_card(1, states[1].hand[0])).is_true()


# --- Trick resolution ---

func test_trick_resolves_after_five_cards() -> void:
	var mgr = _make_manager(0)
	for i in range(5):
		mgr.play_card(i, mgr.states[i].hand[0])
	assert_int(mgr.trick_number).is_equal(1)
	assert_int(mgr.current_trick.size()).is_equal(0)
	assert_int(mgr.lead_suit).is_equal(-1)
	assert_bool(mgr.joker_called).is_false()


func test_trick_winner_leads_next() -> void:
	var states = _make_states()
	states[3].hand[0] = CardScript.new(H, CardScript.Rank.ACE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	for i in range(5):
		mgr.play_card(i, mgr.states[i].hand[0])
	assert_int(mgr.last_trick_winner).is_equal(3)
	assert_int(mgr.current_turn).is_equal(3)


func test_opposition_winner_gets_point_cards() -> void:
	var states = _make_states()
	states[0].hand[0] = CardScript.new(H, CardScript.Rank.ACE)
	states[2].hand[0] = CardScript.new(H, CardScript.Rank.KING)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 1, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	mgr.current_turn = 0
	for i in range(5):
		mgr.play_card(i, mgr.states[i].hand[0])
	assert_int(mgr.states[0].point_cards.size()).is_greater(0)


func test_declarer_winner_cards_go_face_down() -> void:
	var states = _make_states()
	states[0].hand[0] = CardScript.new(H, CardScript.Rank.ACE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	for i in range(5):
		mgr.play_card(i, mgr.states[i].hand[0])
	assert_int(mgr.states[0].point_cards.size()).is_equal(0)
	assert_int(mgr.face_down_pile.size()).is_equal(5)


func test_game_over_after_ten_tricks() -> void:
	var mgr = _make_manager(0)
	assert_bool(mgr.is_game_over()).is_false()
	mgr.trick_number = 10
	assert_bool(mgr.is_game_over()).is_true()


func test_first_trick_winner_friend() -> void:
	var states = _make_states()
	states[3].hand[0] = CardScript.new(H, CardScript.Rank.ACE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.FIRST_TRICK_WINNER}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	for i in range(5):
		mgr.play_card(i, mgr.states[i].hand[0])
	assert_bool(mgr.friend_revealed).is_true()
	assert_int(mgr.friend_index).is_equal(3)


func test_first_trick_winner_declarer_no_friend() -> void:
	var states = _make_states()
	states[0].hand[0] = CardScript.new(H, CardScript.Rank.ACE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.FIRST_TRICK_WINNER}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	for i in range(5):
		mgr.play_card(i, mgr.states[i].hand[0])
	assert_bool(mgr.friend_revealed).is_false()


func test_friend_reveal_moves_points_to_face_down() -> void:
	var states = _make_states()
	states[2].hand[0] = CardScript.new(H, CardScript.Rank.ACE)
	var friend_card = CardScript.new(D, CardScript.Rank.ACE)
	states[2].hand[1] = friend_card
	var friend_call := {
		"type": DeclarerPhaseScript.FriendCallType.CARD,
		"card": friend_card,
	}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 1
	mgr.current_turn = 2
	for i in range(5):
		var pi: int = (2 + i) % 5
		mgr.play_card(pi, mgr.states[pi].hand[0])
	assert_int(mgr.states[2].point_cards.size()).is_greater(0)
	mgr.current_turn = 2
	mgr.play_card(2, friend_card)
	assert_bool(mgr.friend_revealed).is_true()
	assert_int(mgr.states[2].point_cards.size()).is_equal(0)


# --- Custom joker call card ---

func test_custom_joker_call_card() -> void:
	var opts = GameOptionsScript.new()
	opts.alter_joker_call_suit = CardScript.Suit.HEART
	opts.alter_joker_call_rank = CardScript.Rank.THREE
	var states = _make_states()
	# Default joker call (C3) should not work when giruda != club
	states[0].hand[0] = CardScript.new(H, CardScript.Rank.THREE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call, opts)
	mgr.trick_number = 1
	# H3 is the alter joker call for spade giruda? No - default is C3, alter is H3
	# Wait, the logic: if giruda == club, use alter. Otherwise use default (C3).
	# With custom opts: if giruda == club, use alter_joker_call. Otherwise use default (C3).
	# Actually we need to rethink: the joker call card should just use default C3 normally,
	# and alter when giruda is club. The alter is customizable.
	# So H3 should NOT be joker call when giruda=spade. C3 should be.
	assert_bool(mgr.play_card_with_joker_call(0, states[0].hand[0])).is_false()


func test_custom_alter_joker_call_when_club_giruda() -> void:
	var opts = GameOptionsScript.new()
	opts.alter_joker_call_suit = CardScript.Suit.HEART
	opts.alter_joker_call_rank = CardScript.Rank.THREE
	var states = _make_states()
	states[0].hand[0] = CardScript.new(H, CardScript.Rank.THREE)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.CLUB, friend_call, opts)
	mgr.trick_number = 1
	assert_bool(mgr.play_card_with_joker_call(0, states[0].hand[0])).is_true()


# --- Last trick friend (막구 프렌드) ---

func test_last_trick_friend_enabled() -> void:
	var opts = GameOptionsScript.new()
	opts.allow_last_trick_friend = true
	var states := []
	for i in range(5):
		var st = PlayStateScript.new()
		st.hand.append(CardScript.new(H, CardScript.Rank.TWO + i))
		states.append(st)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call, opts)
	mgr.trick_number = 9
	for i in range(5):
		mgr.play_card(i, mgr.states[i].hand[0])
	# Player with highest card (H6 = player 4) wins last trick => becomes friend
	assert_bool(mgr.friend_revealed).is_true()
	assert_int(mgr.friend_index).is_equal(4)


func test_last_trick_friend_disabled_by_default() -> void:
	var states := []
	for i in range(5):
		var st = PlayStateScript.new()
		st.hand.append(CardScript.new(H, CardScript.Rank.TWO + i))
		states.append(st)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	mgr.trick_number = 9
	for i in range(5):
		mgr.play_card(i, mgr.states[i].hand[0])
	assert_bool(mgr.friend_revealed).is_false()


func test_last_trick_friend_not_declarer() -> void:
	var opts = GameOptionsScript.new()
	opts.allow_last_trick_friend = true
	var states := []
	for i in range(5):
		var st = PlayStateScript.new()
		st.hand.append(CardScript.new(H, CardScript.Rank.TWO + i))
		states.append(st)
	# Declarer is player 4 who also wins the last trick => no friend reveal
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var mgr = TrickManagerScript.new(states, 4, BiddingStateScript.Giruda.SPADE, friend_call, opts)
	mgr.trick_number = 9
	mgr.current_turn = 0
	for i in range(5):
		mgr.play_card(i, mgr.states[i].hand[0])
	assert_bool(mgr.friend_revealed).is_false()

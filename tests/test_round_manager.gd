extends GdUnitTestSuite

const RoundManagerScript = preload("res://scripts/game_logic/round_manager.gd")
const PlayerScript = preload("res://scripts/game_logic/player.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")
const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")


func _make_players() -> Array:
	var players := []
	for i in range(5):
		players.append(PlayerScript.new("Player%d" % i, i))
	return players


func _make_round(dealer: int = 0) -> RefCounted:
	return RoundManagerScript.new(_make_players(), dealer, 13)


# --- Phase progression ---

func test_initial_phase_is_deal() -> void:
	var rm = _make_round()
	assert_int(rm.phase).is_equal(RoundManagerScript.Phase.DEAL)


func test_deal_moves_to_bidding() -> void:
	var rm = _make_round()
	rm.do_deal()
	assert_int(rm.phase).is_equal(RoundManagerScript.Phase.BIDDING)
	assert_int(rm.bidding_manager.states.size()).is_equal(5)


func test_deal_distributes_cards() -> void:
	var rm = _make_round()
	rm.do_deal()
	for state in rm.bidding_manager.states:
		assert_bool(state != null).is_true()
	assert_int(rm.kitty.size()).is_equal(3)


func test_bidding_to_declarer_phase() -> void:
	var rm = _make_round()
	rm.do_deal()
	rm.bidding_manager.place_bid(0, 13, BiddingStateScript.Giruda.SPADE)
	rm.bidding_manager.pass_turn(1)
	rm.bidding_manager.pass_turn(2)
	rm.bidding_manager.pass_turn(3)
	rm.bidding_manager.pass_turn(4)
	rm.advance_from_bidding()
	assert_int(rm.phase).is_equal(RoundManagerScript.Phase.DECLARER)
	assert_bool(rm.declarer_phase != null).is_true()


func test_declarer_to_play_phase() -> void:
	var rm = _make_round()
	rm.do_deal()
	rm.bidding_manager.place_bid(0, 13, BiddingStateScript.Giruda.SPADE)
	rm.bidding_manager.pass_turn(1)
	rm.bidding_manager.pass_turn(2)
	rm.bidding_manager.pass_turn(3)
	rm.bidding_manager.pass_turn(4)
	rm.advance_from_bidding()
	rm.declarer_phase.skip_first_change()
	rm.declarer_phase.reveal_kitty()
	var to_discard := [rm.declarer_phase.hand[0], rm.declarer_phase.hand[1], rm.declarer_phase.hand[2]]
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	rm.declarer_phase.finalize(to_discard, friend_call)
	rm.advance_from_declarer()
	assert_int(rm.phase).is_equal(RoundManagerScript.Phase.PLAY)
	assert_bool(rm.trick_manager != null).is_true()


func test_phase_cannot_skip() -> void:
	var rm = _make_round()
	assert_bool(rm.advance_from_bidding()).is_false()
	assert_bool(rm.advance_from_declarer()).is_false()


# --- Options passed through ---

func test_options_passed_to_bidding_manager() -> void:
	var opts = GameOptionsScript.new()
	opts.min_bid = 11
	var rm = RoundManagerScript.new(_make_players(), 0, 13, opts)
	rm.do_deal()
	assert_int(rm.bidding_manager.minimum_bid).is_equal(11)


func test_options_default_when_not_provided() -> void:
	var rm = _make_round()
	rm.do_deal()
	assert_int(rm.bidding_manager.minimum_bid).is_equal(13)

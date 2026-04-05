extends GdUnitTestSuite

const BotManagerScript = preload("res://scripts/ai/bot_manager.gd")
const BSWStrategyScript = preload("res://scripts/ai/bsw_strategy.gd")
const BiddingManagerScript = preload("res://scripts/game_logic/bidding_manager.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")
const TrickManagerScript = preload("res://scripts/game_logic/trick_manager.gd")
const PlayStateScript = preload("res://scripts/game_logic/play_state.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")

var S := CardScript.Suit.SPADE
var D := CardScript.Suit.DIAMOND
var H := CardScript.Suit.HEART
var C := CardScript.Suit.CLUB


func _card(suit: int, rank: int):
	return CardScript.new(suit, rank)


func _make_bot(index: int = 0) -> RefCounted:
	return BotManagerScript.new(BSWStrategyScript.new(), index)


func test_bot_can_bid_or_pass() -> void:
	var hands := []
	for i in range(5):
		var hand := []
		for j in range(10):
			hand.append(_card(H, CardScript.Rank.TWO + j))
		hands.append(hand)
	var bm = BiddingManagerScript.new(5, 0, hands, 13)
	var bot = _make_bot(0)
	bot.do_bidding_turn(bm)
	assert_bool(bm.states[0].passed or bm.states[0].bid_count > 0).is_true()


func test_bot_does_declarer_phase() -> void:
	var hand := []
	for i in range(10):
		hand.append(_card(S, CardScript.Rank.TWO + i))
	var kitty := [_card(H, CardScript.Rank.TWO), _card(H, CardScript.Rank.THREE), _card(H, CardScript.Rank.FOUR)]
	var dp = DeclarerPhaseScript.new(hand, kitty, 13, BiddingStateScript.Giruda.SPADE)
	var bot = _make_bot(0)
	bot.do_declarer_phase(dp)
	assert_bool(dp.is_finished).is_true()
	assert_int(dp.discarded.size()).is_equal(3)
	assert_int(dp.friend_call_type).is_greater_equal(0)


func test_bot_plays_trick_lead() -> void:
	var states := []
	for i in range(5):
		var st = PlayStateScript.new()
		for j in range(10):
			st.hand.append(_card(H, CardScript.Rank.TWO + j))
		states.append(st)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var tm = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	var bot = _make_bot(0)
	bot.do_trick_turn(tm)
	assert_int(tm.current_trick.size()).is_equal(1)
	assert_int(tm.states[0].hand.size()).is_equal(9)


func test_bot_plays_trick_follow() -> void:
	var states := []
	for i in range(5):
		var st = PlayStateScript.new()
		for j in range(10):
			st.hand.append(_card(H, CardScript.Rank.TWO + j))
		states.append(st)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var tm = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)
	tm.play_card(0, states[0].hand[0])
	var bot = _make_bot(1)
	bot.do_trick_turn(tm)
	assert_int(tm.current_trick.size()).is_equal(2)


func test_strategy_is_swappable() -> void:
	var bot1 = BotManagerScript.new(BSWStrategyScript.new(), 0)
	var bot2 = BotManagerScript.new(BSWStrategyScript.new(), 1)
	assert_bool(bot1.strategy != null).is_true()
	assert_bool(bot2.strategy != null).is_true()

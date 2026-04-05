extends GdUnitTestSuite

const XiaoStrategyScript = preload("res://scripts/ai/xiao_strategy.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const CardValidatorScript = preload("res://scripts/game_logic/card_validator.gd")
const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")

var S := CardScript.Suit.SPADE
var D := CardScript.Suit.DIAMOND
var H := CardScript.Suit.HEART
var C := CardScript.Suit.CLUB


func _card(suit: int, rank: int):
	return CardScript.new(suit, rank)


func _joker():
	return CardScript.create_joker()


func _empty_used() -> Array:
	return [{}, {}, {}, {}]


func _make_strategy() -> RefCounted:
	return XiaoStrategyScript.new()


# --- Bidding Tests ---

func test_bid_strong_hand_does_not_pass() -> void:
	var strat = _make_strategy()
	var hand := []
	for i in range(8):
		hand.append(_card(S, CardScript.Rank.ACE - i))
	hand.append(_joker())
	hand.append(_card(D, CardScript.Rank.ACE))
	var result: Dictionary = strat.decide_bid(hand, 13, 0, BiddingStateScript.Giruda.NONE)
	assert_bool(result["pass"]).is_false()


func test_bid_weak_hand_passes() -> void:
	var strat = _make_strategy()
	var hand := []
	for i in range(10):
		hand.append(_card([S, D, H, C][i % 4], CardScript.Rank.TWO + (i % 3)))
	var result: Dictionary = strat.decide_bid(hand, 13, 20, BiddingStateScript.Giruda.NONE)
	assert_bool(result["pass"]).is_true()


func test_bid_evaluates_all_giruda_options() -> void:
	var strat = _make_strategy()
	var hand := []
	for i in range(7):
		hand.append(_card(H, CardScript.Rank.ACE - i))
	hand.append(_card(S, CardScript.Rank.TWO))
	hand.append(_card(D, CardScript.Rank.TWO))
	hand.append(_card(C, CardScript.Rank.TWO))
	var result: Dictionary = strat.decide_bid(hand, 13, 0, BiddingStateScript.Giruda.NONE)
	assert_bool(result["pass"]).is_false()
	assert_int(result["giruda"]).is_not_equal(BiddingStateScript.Giruda.NONE)


func test_bid_mighty_increases_score() -> void:
	var strat = _make_strategy()
	var hand_with := [_card(S, CardScript.Rank.ACE)]
	for i in range(9):
		hand_with.append(_card(H, CardScript.Rank.TWO + i))
	var result_with: Dictionary = strat.decide_bid(hand_with, 13, 0, BiddingStateScript.Giruda.NONE)

	var hand_without := [_card(S, CardScript.Rank.TWO)]
	for i in range(9):
		hand_without.append(_card(H, CardScript.Rank.TWO + i))
	var result_without: Dictionary = strat.decide_bid(hand_without, 13, 0, BiddingStateScript.Giruda.NONE)

	var bid_with: int = result_with.get("bid", 0)
	var bid_without: int = result_without.get("bid", 0)
	assert_int(bid_with).is_greater_equal(bid_without)


# --- Giruda Change Tests ---

func test_giruda_change_when_better_option() -> void:
	var strat = _make_strategy()
	var hand := []
	for i in range(8):
		hand.append(_card(S, CardScript.Rank.ACE - i))
	hand.append(_card(H, CardScript.Rank.TWO))
	hand.append(_card(H, CardScript.Rank.THREE))
	var result: Dictionary = strat.decide_giruda_change(hand, 13, BiddingStateScript.Giruda.HEART, 1)
	if result["change"]:
		assert_int(result["giruda"]).is_not_equal(BiddingStateScript.Giruda.HEART)


func test_giruda_change_returns_valid_result() -> void:
	var strat = _make_strategy()
	var hand := []
	for i in range(8):
		hand.append(_card(S, CardScript.Rank.ACE - i))
	hand.append(_card(H, CardScript.Rank.TWO))
	hand.append(_card(D, CardScript.Rank.TWO))
	var result: Dictionary = strat.decide_giruda_change(hand, 13, BiddingStateScript.Giruda.SPADE, 1)
	assert_bool(result.has("change")).is_true()


# --- Friend Selection Tests ---

func test_friend_selects_mighty_first() -> void:
	var strat = _make_strategy()
	var hand := []
	for i in range(10):
		hand.append(_card(S, CardScript.Rank.TWO + i))
	var result: Dictionary = strat.decide_friend(hand, BiddingStateScript.Giruda.SPADE)
	assert_int(result["type"]).is_equal(DeclarerPhaseScript.FriendCallType.CARD)
	var fc = result["card"]
	assert_bool(CardValidatorScript.is_mighty(fc, BiddingStateScript.Giruda.SPADE)).is_true()


func test_friend_selects_joker_if_have_mighty() -> void:
	var strat = _make_strategy()
	var hand := [_card(D, CardScript.Rank.ACE)]
	for i in range(9):
		hand.append(_card(S, CardScript.Rank.TWO + i))
	var result: Dictionary = strat.decide_friend(hand, BiddingStateScript.Giruda.SPADE)
	assert_int(result["type"]).is_equal(DeclarerPhaseScript.FriendCallType.CARD)
	assert_bool(result["card"].is_joker).is_true()


# --- Card Lead Tests ---

func test_lead_returns_valid_card() -> void:
	var strat = _make_strategy()
	var hand := []
	for i in range(10):
		hand.append(_card(H, CardScript.Rank.TWO + i))
	var result: Dictionary = strat.decide_card_lead(hand, BiddingStateScript.Giruda.SPADE, 1, _empty_used())
	assert_bool(result.has("card")).is_true()
	assert_bool(result["card"] != null).is_true()


func test_lead_joker_has_suit() -> void:
	var strat = _make_strategy()
	var hand := [_joker()]
	for i in range(5):
		hand.append(_card(H, CardScript.Rank.TWO + i))
	for i in range(4):
		hand.append(_card(D, CardScript.Rank.TWO + i))
	var result: Dictionary = strat.decide_card_lead(hand, BiddingStateScript.Giruda.SPADE, 1, _empty_used())
	if result["card"].is_joker:
		assert_bool(result.has("joker_suit")).is_true()


func test_lead_prefers_top_card_in_suit() -> void:
	var strat = _make_strategy()
	var used := _empty_used()
	for r in range(12, 11, -1):
		used[S][r] = true
	var hand := [_card(S, CardScript.Rank.QUEEN), _card(H, CardScript.Rank.TWO), _card(D, CardScript.Rank.TWO)]
	var result: Dictionary = strat.decide_card_lead(hand, BiddingStateScript.Giruda.HEART, 1, used)
	assert_bool(result["card"] != null).is_true()


# --- Card Follow Tests ---

func test_follow_returns_valid_card() -> void:
	var strat = _make_strategy()
	var hand := []
	for i in range(10):
		hand.append(_card(H, CardScript.Rank.TWO + i))
	var result: Dictionary = strat.decide_card_follow(hand, H, BiddingStateScript.Giruda.SPADE, false, _empty_used())
	assert_bool(result.has("card")).is_true()
	assert_bool(result["card"].suit == H).is_true()


func test_follow_plays_low_when_no_choice() -> void:
	var strat = _make_strategy()
	var hand := [
		_card(H, CardScript.Rank.TWO),
		_card(H, CardScript.Rank.THREE),
		_card(H, CardScript.Rank.FOUR),
	]
	var result: Dictionary = strat.decide_card_follow(hand, H, BiddingStateScript.Giruda.SPADE, false, _empty_used())
	assert_int(result["card"].rank).is_less_equal(CardScript.Rank.FOUR)


func test_follow_prefers_non_point_cards() -> void:
	var strat = _make_strategy()
	var hand := [
		_card(H, CardScript.Rank.TWO),
		_card(H, CardScript.Rank.ACE),
		_card(H, CardScript.Rank.KING),
	]
	var result: Dictionary = strat.decide_card_follow(hand, H, BiddingStateScript.Giruda.SPADE, false, _empty_used())
	assert_int(result["card"].rank).is_equal(CardScript.Rank.TWO)


func test_follow_off_suit_prefers_cheap() -> void:
	var strat = _make_strategy()
	var hand := [
		_card(D, CardScript.Rank.TWO),
		_card(D, CardScript.Rank.ACE),
		_card(S, CardScript.Rank.KING),
	]
	var result: Dictionary = strat.decide_card_follow(hand, H, BiddingStateScript.Giruda.CLUB, false, _empty_used())
	assert_bool(result["card"].rank <= CardScript.Rank.THREE or result["card"].suit != S).is_true()


# --- Joker Call Tests ---

func test_joker_call_true_when_have_card() -> void:
	var strat = _make_strategy()
	var hand := [_card(C, CardScript.Rank.THREE), _card(H, CardScript.Rank.TWO)]
	assert_bool(strat.decide_joker_call(hand, BiddingStateScript.Giruda.SPADE, 5)).is_true()


func test_joker_call_false_on_first_trick() -> void:
	var strat = _make_strategy()
	var hand := [_card(C, CardScript.Rank.THREE), _card(H, CardScript.Rank.TWO)]
	assert_bool(strat.decide_joker_call(hand, BiddingStateScript.Giruda.SPADE, 0)).is_false()


func test_joker_call_false_on_last_trick() -> void:
	var strat = _make_strategy()
	var hand := [_card(C, CardScript.Rank.THREE)]
	assert_bool(strat.decide_joker_call(hand, BiddingStateScript.Giruda.SPADE, 9)).is_false()


func test_joker_call_false_without_card() -> void:
	var strat = _make_strategy()
	var hand := [_card(H, CardScript.Rank.TWO), _card(S, CardScript.Rank.TWO)]
	assert_bool(strat.decide_joker_call(hand, BiddingStateScript.Giruda.SPADE, 5)).is_false()


func test_joker_call_club_giruda_uses_spade_three() -> void:
	var strat = _make_strategy()
	var hand := [_card(S, CardScript.Rank.THREE), _card(H, CardScript.Rank.TWO)]
	assert_bool(strat.decide_joker_call(hand, BiddingStateScript.Giruda.CLUB, 5)).is_true()


# --- Discard Tests ---

func test_discard_returns_three_cards() -> void:
	var strat = _make_strategy()
	var hand := []
	for i in range(13):
		hand.append(_card([S, D, H, C][i % 4], CardScript.Rank.TWO + (i % 12)))
	var result: Array = strat.decide_discard(hand, BiddingStateScript.Giruda.SPADE)
	assert_int(result.size()).is_equal(3)


func test_discard_does_not_discard_mighty() -> void:
	var strat = _make_strategy()
	var hand := [_card(S, CardScript.Rank.ACE)]
	for i in range(12):
		hand.append(_card([D, H, C][i % 3], CardScript.Rank.TWO + (i % 10)))
	var result: Array = strat.decide_discard(hand, BiddingStateScript.Giruda.DIAMOND)
	for card in result:
		assert_bool(CardValidatorScript.is_mighty(card, BiddingStateScript.Giruda.DIAMOND)).is_false()


func test_discard_prefers_low_non_giruda() -> void:
	var strat = _make_strategy()
	var hand := []
	for i in range(7):
		hand.append(_card(S, CardScript.Rank.ACE - i))
	hand.append(_card(H, CardScript.Rank.TWO))
	hand.append(_card(H, CardScript.Rank.THREE))
	hand.append(_card(H, CardScript.Rank.FOUR))
	hand.append(_card(D, CardScript.Rank.TWO))
	hand.append(_card(D, CardScript.Rank.THREE))
	hand.append(_card(C, CardScript.Rank.TWO))
	var result: Array = strat.decide_discard(hand, BiddingStateScript.Giruda.SPADE)
	for card in result:
		assert_bool(card.suit != S).is_true()


# --- Probability Model Tests ---

func test_init_probability_sets_friend_prob() -> void:
	var strat = _make_strategy()
	strat.init_probability(5, 0, 1, BiddingStateScript.Giruda.SPADE)
	assert_float(strat.get_friend_probability(0)).is_equal(0.0)
	assert_float(strat.get_friend_probability(1)).is_greater(0.0)
	assert_float(strat.get_friend_probability(2)).is_greater(0.0)


func test_suit_prob_drops_on_off_suit_play() -> void:
	var strat = _make_strategy()
	strat.init_probability(5, 0, 1, BiddingStateScript.Giruda.SPADE)
	var initial_prob: float = strat.get_suit_probability(2, H)
	strat.update_card_played(2, _card(D, CardScript.Rank.FIVE), H)
	var after_prob: float = strat.get_suit_probability(2, H)
	assert_float(after_prob).is_equal(0.0)


func test_suit_prob_unchanged_on_suit_follow() -> void:
	var strat = _make_strategy()
	strat.init_probability(5, 0, 1, BiddingStateScript.Giruda.SPADE)
	var initial_prob: float = strat.get_suit_probability(2, H)
	strat.update_card_played(2, _card(H, CardScript.Rank.FIVE), H)
	var after_prob: float = strat.get_suit_probability(2, H)
	assert_float(after_prob).is_equal(initial_prob)


func test_friend_probability_adjustment() -> void:
	var strat = _make_strategy()
	strat.init_probability(5, 0, 1, BiddingStateScript.Giruda.SPADE)
	var before: float = strat.get_friend_probability(2)
	strat.update_friend_probability(2, 0.3)
	var after: float = strat.get_friend_probability(2)
	assert_float(after).is_greater(before)


func test_friend_probability_clamped() -> void:
	var strat = _make_strategy()
	strat.init_probability(5, 0, 1, BiddingStateScript.Giruda.SPADE)
	strat.update_friend_probability(2, 5.0)
	assert_float(strat.get_friend_probability(2)).is_less_equal(1.0)
	strat.update_friend_probability(2, -10.0)
	assert_float(strat.get_friend_probability(2)).is_greater_equal(0.0)


func test_friend_probability_redistributes() -> void:
	var strat = _make_strategy()
	strat.init_probability(5, 0, 1, BiddingStateScript.Giruda.SPADE)
	var before_3: float = strat.get_friend_probability(3)
	strat.update_friend_probability(2, 0.3)
	var after_3: float = strat.get_friend_probability(3)
	assert_float(after_3).is_less(before_3)


# --- Integration with BotManager ---

func test_strategy_works_with_bot_manager() -> void:
	var BotManagerScript = preload("res://scripts/ai/bot_manager.gd")
	var BiddingManagerScript = preload("res://scripts/game_logic/bidding_manager.gd")
	var strat = _make_strategy()
	var bot = BotManagerScript.new(strat, 0)

	var hands := []
	for i in range(5):
		var hand := []
		for j in range(10):
			hand.append(_card(H, CardScript.Rank.TWO + j))
		hands.append(hand)

	var bm = BiddingManagerScript.new(5, 0, hands, 13)
	bot.do_bidding_turn(bm)
	assert_bool(bm.states[0].passed or bm.states[0].bid_count > 0).is_true()


func test_strategy_does_declarer_phase() -> void:
	var BotManagerScript = preload("res://scripts/ai/bot_manager.gd")
	var strat = _make_strategy()
	var bot = BotManagerScript.new(strat, 0)

	var hand := []
	for i in range(10):
		hand.append(_card(S, CardScript.Rank.TWO + i))
	var kitty := [_card(H, CardScript.Rank.TWO), _card(H, CardScript.Rank.THREE), _card(H, CardScript.Rank.FOUR)]
	var dp = DeclarerPhaseScript.new(hand, kitty, 13, BiddingStateScript.Giruda.SPADE)

	bot.do_declarer_phase(dp)
	assert_bool(dp.is_finished).is_true()
	assert_int(dp.discarded.size()).is_equal(3)


func test_strategy_plays_trick() -> void:
	var BotManagerScript = preload("res://scripts/ai/bot_manager.gd")
	var PlayStateScript = preload("res://scripts/game_logic/play_state.gd")
	var TrickManagerScript = preload("res://scripts/game_logic/trick_manager.gd")
	var strat = _make_strategy()
	var bot = BotManagerScript.new(strat, 0)

	var states := []
	for i in range(5):
		var st = PlayStateScript.new()
		for j in range(10):
			st.hand.append(_card(H, CardScript.Rank.TWO + j))
		states.append(st)
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	var tm = TrickManagerScript.new(states, 0, BiddingStateScript.Giruda.SPADE, friend_call)

	bot.do_trick_turn(tm)
	assert_int(tm.current_trick.size()).is_equal(1)
	assert_int(tm.states[0].hand.size()).is_equal(9)

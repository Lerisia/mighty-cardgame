extends GdUnitTestSuite

const RoundManagerScript = preload("res://scripts/game_logic/round_manager.gd")
const BotManagerScript = preload("res://scripts/ai/bot_manager.gd")
const BSWStrategyScript = preload("res://scripts/ai/bsw_strategy.gd")
const XiaoStrategyScript = preload("res://scripts/ai/xiao_strategy.gd")
const PlayerScript = preload("res://scripts/game_logic/player.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")


func _make_players() -> Array:
	var players := []
	for i in range(5):
		players.append(PlayerScript.new("Bot%d" % i, i, true))
	return players


func _make_bots() -> Array:
	var bots := []
	for i in range(5):
		bots.append(BotManagerScript.new(BSWStrategyScript.new(), i))
	return bots


func test_full_round_completes() -> void:
	var players = _make_players()
	var bots = _make_bots()
	var rm = null
	var redeal: int = 0
	while redeal < 10:
		rm = RoundManagerScript.new(players, 0, 13)
		rm.do_deal()
		assert_int(rm.phase).is_equal(RoundManagerScript.Phase.BIDDING)

		var safety: int = 0
		while not rm.bidding_manager.is_finished() and not _all_passed(rm.bidding_manager) and safety < 100:
			var turn: int = rm.bidding_manager.current_turn
			bots[turn].do_bidding_turn(rm.bidding_manager)
			safety += 1
		if _all_passed(rm.bidding_manager):
			redeal += 1
			continue
		break

	assert_bool(rm.bidding_manager.is_finished()).is_true()

	rm.advance_from_bidding()
	assert_int(rm.phase).is_equal(RoundManagerScript.Phase.DECLARER)

	# Declarer phase
	var declarer: int = rm.declarer_index
	bots[declarer].do_declarer_phase(rm.declarer_phase)
	assert_bool(rm.declarer_phase.is_finished).is_true()

	rm.advance_from_declarer()
	assert_int(rm.phase).is_equal(RoundManagerScript.Phase.PLAY)

	# 10 tricks
	var safety: int = 0
	while not rm.trick_manager.is_game_over() and safety < 100:
		var turn: int = rm.trick_manager.current_turn
		bots[turn].do_trick_turn(rm.trick_manager)
		safety += 1
	assert_bool(rm.trick_manager.is_game_over()).is_true()

	rm.advance_from_play()
	assert_int(rm.phase).is_equal(RoundManagerScript.Phase.SCORING)

	rm.calculate_scores()
	assert_int(rm.phase).is_equal(RoundManagerScript.Phase.FINISHED)

	# Score sum should be zero (zero-sum game)
	var total := 0
	for p in players:
		total += p.score
	assert_int(total).is_equal(0)


func test_multiple_rounds() -> void:
	var players = _make_players()
	var bots = _make_bots()
	var dealer := 0

	for round_num in range(3):
		var rm = null
		var redeal: int = 0
		while redeal < 10:
			rm = RoundManagerScript.new(players, dealer, 13)
			rm.do_deal()

			var safety: int = 0
			while not rm.bidding_manager.is_finished() and not _all_passed(rm.bidding_manager) and safety < 100:
				var turn: int = rm.bidding_manager.current_turn
				bots[turn].do_bidding_turn(rm.bidding_manager)
				safety += 1
			if _all_passed(rm.bidding_manager):
				redeal += 1
				continue
			break

		assert_bool(rm.bidding_manager.is_finished()).is_true()

		assert_bool(rm.advance_from_bidding()).is_true()
		bots[rm.declarer_index].do_declarer_phase(rm.declarer_phase)
		assert_bool(rm.advance_from_declarer()).is_true()

		var safety: int = 0
		while not rm.trick_manager.is_game_over() and safety < 100:
			var turn: int = rm.trick_manager.current_turn
			bots[turn].do_trick_turn(rm.trick_manager)
			safety += 1

		rm.advance_from_play()
		rm.calculate_scores()

		dealer = (dealer + 1) % 5

	var total := 0
	for p in players:
		total += p.score
	assert_int(total).is_equal(0)


func _all_passed(bm) -> bool:
	for i in range(bm.player_count):
		if not bm.states[i].passed:
			return false
	return bm.highest_bidder < 0


func _run_round(players: Array, bots: Array, dealer: int) -> void:
	var redeal_count: int = 0
	var rm = null
	while redeal_count < 10:
		rm = RoundManagerScript.new(players, dealer, 13)
		rm.do_deal()

		var safety: int = 0
		while not rm.bidding_manager.is_finished() and not _all_passed(rm.bidding_manager) and safety < 100:
			var turn: int = rm.bidding_manager.current_turn
			bots[turn].do_bidding_turn(rm.bidding_manager)
			safety += 1

		if _all_passed(rm.bidding_manager):
			redeal_count += 1
			continue
		break

	rm.advance_from_bidding()
	bots[rm.declarer_index].do_declarer_phase(rm.declarer_phase)
	rm.advance_from_declarer()

	var safety: int = 0
	while not rm.trick_manager.is_game_over() and safety < 100:
		var turn: int = rm.trick_manager.current_turn
		bots[turn].do_trick_turn(rm.trick_manager)
		safety += 1

	rm.advance_from_play()
	rm.calculate_scores()


func test_xiao_full_round() -> void:
	var players := []
	var bots := []
	for i in range(5):
		players.append(PlayerScript.new("Xiao%d" % i, i, true))
		bots.append(BotManagerScript.new(XiaoStrategyScript.new(), i))

	_run_round(players, bots, 0)
	var total := 0
	for p in players:
		total += p.score
	assert_int(total).is_equal(0)


func test_mixed_bsw_and_xiao() -> void:
	var players := []
	var bots := []
	for i in range(5):
		players.append(PlayerScript.new("Player%d" % i, i, true))
		if i % 2 == 0:
			bots.append(BotManagerScript.new(BSWStrategyScript.new(), i))
		else:
			bots.append(BotManagerScript.new(XiaoStrategyScript.new(), i))

	for round_num in range(3):
		_run_round(players, bots, round_num % 5)

	var total := 0
	for p in players:
		total += p.score
	assert_int(total).is_equal(0)


func test_xiao_multiple_rounds() -> void:
	var players := []
	var bots := []
	for i in range(5):
		players.append(PlayerScript.new("Xiao%d" % i, i, true))
		bots.append(BotManagerScript.new(XiaoStrategyScript.new(), i))

	for round_num in range(5):
		_run_round(players, bots, round_num % 5)

	var total := 0
	for p in players:
		total += p.score
	assert_int(total).is_equal(0)

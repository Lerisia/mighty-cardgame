extends GdUnitTestSuite

const ScoreCalcScript = preload("res://scripts/game_logic/score_calculator.gd")
const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")


# --- Ruling party wins ---

func test_ruling_party_wins_minimum_bid() -> void:
	var result = ScoreCalcScript.calculate(13, 13, 13, false, false, false)
	assert_int(result["declarer"]).is_equal(0)
	assert_int(result["friend"]).is_equal(0)
	assert_int(result["opposition"]).is_equal(0)


func test_ruling_party_wins_bid_14() -> void:
	var result = ScoreCalcScript.calculate(14, 14, 13, false, false, false)
	assert_int(result["declarer"]).is_equal(4)
	assert_int(result["friend"]).is_equal(2)
	assert_int(result["opposition"]).is_equal(-2)


func test_ruling_party_wins_with_extra_points() -> void:
	var result = ScoreCalcScript.calculate(13, 16, 13, false, false, false)
	assert_int(result["declarer"]).is_equal(6)
	assert_int(result["friend"]).is_equal(3)
	assert_int(result["opposition"]).is_equal(-3)


func test_ruling_party_wins_high_bid() -> void:
	var result = ScoreCalcScript.calculate(17, 18, 13, false, false, false)
	assert_int(result["declarer"]).is_equal(18)
	assert_int(result["friend"]).is_equal(9)
	assert_int(result["opposition"]).is_equal(-9)


# --- Opposition wins ---

func test_opposition_wins() -> void:
	var result = ScoreCalcScript.calculate(15, 12, 13, false, false, false)
	assert_int(result["declarer"]).is_equal(-6)
	assert_int(result["friend"]).is_equal(-3)
	assert_int(result["opposition"]).is_equal(3)


func test_opposition_wins_barely() -> void:
	var result = ScoreCalcScript.calculate(13, 12, 13, false, false, false)
	assert_int(result["declarer"]).is_equal(-2)
	assert_int(result["friend"]).is_equal(-1)
	assert_int(result["opposition"]).is_equal(1)


# --- No friend ---

func test_no_friend_wins() -> void:
	var result = ScoreCalcScript.calculate(14, 14, 13, true, false, false)
	assert_int(result["declarer"]).is_equal(8)
	assert_int(result["friend"]).is_equal(0)
	assert_int(result["opposition"]).is_equal(-2)


func test_no_friend_loses() -> void:
	var result = ScoreCalcScript.calculate(15, 12, 13, true, false, false)
	assert_int(result["declarer"]).is_equal(-12)
	assert_int(result["friend"]).is_equal(0)
	assert_int(result["opposition"]).is_equal(3)


# --- Min bid setting ---

func test_different_min_bid() -> void:
	var result = ScoreCalcScript.calculate(14, 14, 11, false, false, false)
	assert_int(result["declarer"]).is_equal(12)
	assert_int(result["friend"]).is_equal(6)
	assert_int(result["opposition"]).is_equal(-6)


# --- Run (20 points) ---

func test_run_with_friend() -> void:
	var result = ScoreCalcScript.calculate(15, 20, 13, false, false, false)
	var base: int = (15 - 13) * 2 + (20 - 15)
	var multiplier := 2
	assert_int(result["declarer"]).is_equal(base * multiplier * 2)
	assert_int(result["friend"]).is_equal(base * multiplier)
	assert_int(result["opposition"]).is_equal(-base * multiplier)


# --- No giruda win ---

func test_no_giruda_doubles_score() -> void:
	var result = ScoreCalcScript.calculate(13, 15, 13, false, true, false)
	var base: int = (13 - 13) * 2 + (15 - 13)
	assert_int(result["declarer"]).is_equal(base * 2 * 2)
	assert_int(result["friend"]).is_equal(base * 2)
	assert_int(result["opposition"]).is_equal(-base * 2)


# --- Run + no giruda stacks ---

func test_run_and_no_giruda_stacks() -> void:
	var result = ScoreCalcScript.calculate(13, 20, 13, false, true, false)
	var base: int = (13 - 13) * 2 + (20 - 13)
	assert_int(result["declarer"]).is_equal(base * 4 * 2)
	assert_int(result["friend"]).is_equal(base * 4)
	assert_int(result["opposition"]).is_equal(-base * 4)


# --- Bid 20 run option ---

func test_bid_20_run_option() -> void:
	var result = ScoreCalcScript.calculate(20, 20, 13, false, false, true)
	var base: int = (20 - 13) * 2 + (20 - 20)
	assert_int(result["declarer"]).is_equal(base * 4 * 2)
	assert_int(result["friend"]).is_equal(base * 4)
	assert_int(result["opposition"]).is_equal(-base * 4)


# --- Back run ---

func test_back_run_default_ruling_10_or_less() -> void:
	var result = ScoreCalcScript.calculate(13, 10, 13, false, false, false)
	assert_bool(result["back_run"]).is_true()
	# base = (13 - 10) = 3, back run doubles: 6
	assert_int(result["declarer"]).is_equal(-6 * 2)
	assert_int(result["friend"]).is_equal(-6)
	assert_int(result["opposition"]).is_equal(6)


func test_no_back_run_ruling_11() -> void:
	var result = ScoreCalcScript.calculate(13, 11, 13, false, false, false)
	assert_bool(result["back_run"]).is_false()
	# base = (13 - 11) = 2, no back run
	assert_int(result["declarer"]).is_equal(-2 * 2)
	assert_int(result["friend"]).is_equal(-2)
	assert_int(result["opposition"]).is_equal(2)


func test_back_run_exactly_10() -> void:
	var result = ScoreCalcScript.calculate(15, 10, 13, false, false, false)
	assert_bool(result["back_run"]).is_true()
	# base = (15 - 10) = 5, back run doubles: 10
	assert_int(result["declarer"]).is_equal(-10 * 2)
	assert_int(result["friend"]).is_equal(-10)
	assert_int(result["opposition"]).is_equal(10)


func test_back_run_zero_points() -> void:
	var result = ScoreCalcScript.calculate(13, 0, 13, false, false, false)
	assert_bool(result["back_run"]).is_true()
	# base = 13, back run doubles: 26
	assert_int(result["declarer"]).is_equal(-26 * 2)
	assert_int(result["friend"]).is_equal(-26)
	assert_int(result["opposition"]).is_equal(26)


func test_back_run_opposition_method() -> void:
	var opts = GameOptionsScript.new()
	opts.back_run_method = GameOptionsScript.BackRunMethod.OPPOSITION_GETS_BID_OR_MORE
	# ruling gets 3, bid 15 => opposition gets 17 >= 15 => back run
	var result = ScoreCalcScript.calculate_with_options(15, 3, 13, false, false, opts)
	assert_bool(result["back_run"]).is_true()
	# base = (15 - 3) = 12, back run doubles: 24
	assert_int(result["declarer"]).is_equal(-24 * 2)
	assert_int(result["friend"]).is_equal(-24)
	assert_int(result["opposition"]).is_equal(24)


func test_no_back_run_opposition_method_below_bid() -> void:
	var opts = GameOptionsScript.new()
	opts.back_run_method = GameOptionsScript.BackRunMethod.OPPOSITION_GETS_BID_OR_MORE
	# ruling gets 7, bid 15 => opposition gets 13 < 15 => no back run
	var result = ScoreCalcScript.calculate_with_options(15, 7, 13, false, false, opts)
	assert_bool(result["back_run"]).is_false()


func test_back_run_no_friend() -> void:
	var result = ScoreCalcScript.calculate(13, 5, 13, true, false, false)
	assert_bool(result["back_run"]).is_true()
	# base = (13 - 5) = 8, back run doubles: 16
	assert_int(result["declarer"]).is_equal(-16 * 4)
	assert_int(result["friend"]).is_equal(0)
	assert_int(result["opposition"]).is_equal(16)


func test_back_run_does_not_apply_on_win() -> void:
	var result = ScoreCalcScript.calculate(13, 13, 13, false, false, false)
	assert_bool(result["back_run"]).is_false()

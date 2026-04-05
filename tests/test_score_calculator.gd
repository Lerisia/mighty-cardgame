extends GdUnitTestSuite

const ScoreCalcScript = preload("res://scripts/game_logic/score_calculator.gd")


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

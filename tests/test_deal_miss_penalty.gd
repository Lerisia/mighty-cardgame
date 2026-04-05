extends GdUnitTestSuite

const DealMissPenaltyScript = preload("res://scripts/game_logic/deal_miss_penalty.gd")
const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")


# --- Fixed penalty ---

func test_fixed_penalty() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_penalty_method = GameOptionsScript.DealMissPenalty.FIXED
	opts.deal_miss_fixed_penalty = 5
	var calc = DealMissPenaltyScript.new(5, opts)
	assert_int(calc.calculate_penalty(0)).is_equal(5)


func test_fixed_penalty_consecutive_same_amount() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_penalty_method = GameOptionsScript.DealMissPenalty.FIXED
	opts.deal_miss_fixed_penalty = 5
	var calc = DealMissPenaltyScript.new(5, opts)
	calc.record_deal_miss(0)
	assert_int(calc.calculate_penalty(0)).is_equal(5)


# --- Doubling penalty ---

func test_doubling_first() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_penalty_method = GameOptionsScript.DealMissPenalty.DOUBLING
	opts.deal_miss_doubling_base = 2
	var calc = DealMissPenaltyScript.new(5, opts)
	assert_int(calc.calculate_penalty(0)).is_equal(2)


func test_doubling_second_consecutive() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_penalty_method = GameOptionsScript.DealMissPenalty.DOUBLING
	opts.deal_miss_doubling_base = 2
	var calc = DealMissPenaltyScript.new(5, opts)
	calc.record_deal_miss(0)
	assert_int(calc.calculate_penalty(0)).is_equal(4)


func test_doubling_third_consecutive() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_penalty_method = GameOptionsScript.DealMissPenalty.DOUBLING
	opts.deal_miss_doubling_base = 2
	var calc = DealMissPenaltyScript.new(5, opts)
	calc.record_deal_miss(0)
	calc.record_deal_miss(0)
	assert_int(calc.calculate_penalty(0)).is_equal(8)


func test_doubling_resets_on_different_dealer() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_penalty_method = GameOptionsScript.DealMissPenalty.DOUBLING
	opts.deal_miss_doubling_base = 2
	var calc = DealMissPenaltyScript.new(5, opts)
	calc.record_deal_miss(0)
	calc.record_deal_miss(0)
	assert_int(calc.calculate_penalty(1)).is_equal(2)


func test_doubling_resets_on_game_played() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_penalty_method = GameOptionsScript.DealMissPenalty.DOUBLING
	opts.deal_miss_doubling_base = 2
	var calc = DealMissPenaltyScript.new(5, opts)
	calc.record_deal_miss(0)
	calc.record_deal_miss(0)
	calc.record_game_played()
	assert_int(calc.calculate_penalty(0)).is_equal(2)


# --- Pot (escrow) ---

func test_pot_starts_at_zero() -> void:
	var calc = DealMissPenaltyScript.new(5)
	assert_int(calc.pot).is_equal(0)


func test_record_deal_miss_adds_to_pot() -> void:
	var calc = DealMissPenaltyScript.new(5)
	var penalty = calc.calculate_penalty(0)
	calc.record_deal_miss(0)
	assert_int(calc.pot).is_equal(penalty)


func test_pot_accumulates() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_penalty_method = GameOptionsScript.DealMissPenalty.DOUBLING
	opts.deal_miss_doubling_base = 2
	var calc = DealMissPenaltyScript.new(5, opts)
	# First deal miss by player 0: penalty 2, pot = 2
	calc.record_deal_miss(0)
	assert_int(calc.pot).is_equal(2)
	# Second consecutive by player 0: penalty 4, pot = 6
	calc.record_deal_miss(0)
	assert_int(calc.pot).is_equal(6)


func test_claim_pot_returns_total_and_resets() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_penalty_method = GameOptionsScript.DealMissPenalty.DOUBLING
	opts.deal_miss_doubling_base = 2
	var calc = DealMissPenaltyScript.new(5, opts)
	calc.record_deal_miss(0)
	calc.record_deal_miss(0)
	var claimed: int = calc.claim_pot()
	assert_int(claimed).is_equal(6)
	assert_int(calc.pot).is_equal(0)


func test_claim_empty_pot() -> void:
	var calc = DealMissPenaltyScript.new(5)
	assert_int(calc.claim_pot()).is_equal(0)


func test_game_played_does_not_clear_pot() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_penalty_method = GameOptionsScript.DealMissPenalty.DOUBLING
	opts.deal_miss_doubling_base = 2
	var calc = DealMissPenaltyScript.new(5, opts)
	calc.record_deal_miss(0)
	calc.record_game_played()
	# Pot persists until a declarer wins and claims it
	assert_int(calc.pot).is_equal(2)


# --- Zero-sum with pot ---

func test_zero_sum_with_pot() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_penalty_method = GameOptionsScript.DealMissPenalty.DOUBLING
	opts.deal_miss_doubling_base = 2
	var calc = DealMissPenaltyScript.new(5, opts)
	# Player 0 deal misses twice, player 2 deal misses once
	var scores := [0, 0, 0, 0, 0]
	var p0 = calc.calculate_penalty(0)
	scores[0] -= p0
	calc.record_deal_miss(0)
	var p1 = calc.calculate_penalty(0)
	scores[0] -= p1
	calc.record_deal_miss(0)
	var p2 = calc.calculate_penalty(2)
	scores[2] -= p2
	calc.record_deal_miss(2)
	# Winner claims pot
	var claimed = calc.claim_pot()
	scores[3] += claimed
	var total := 0
	for s in scores:
		total += s
	assert_int(total).is_equal(0)


# --- Dealer change ---

func test_next_dealer_to_declarer() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_dealer_to_declarer = true
	var calc = DealMissPenaltyScript.new(5, opts)
	assert_int(calc.next_dealer_after_deal_miss(3, 1)).is_equal(1)


func test_next_dealer_keep_current() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_dealer_to_declarer = false
	var calc = DealMissPenaltyScript.new(5, opts)
	assert_int(calc.next_dealer_after_deal_miss(3, 1)).is_equal(3)

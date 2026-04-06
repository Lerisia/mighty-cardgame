extends GdUnitTestSuite

const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")


# === Bidding defaults ===

func test_default_min_bid() -> void:
	var opts = GameOptionsScript.new()
	assert_int(opts.min_bid).is_equal(13)


func test_default_allow_giruda_change_before_kitty() -> void:
	var opts = GameOptionsScript.new()
	assert_bool(opts.allow_giruda_change_before_kitty).is_true()


func test_default_allow_giruda_change_after_kitty() -> void:
	var opts = GameOptionsScript.new()
	assert_bool(opts.allow_giruda_change_after_kitty).is_true()


func test_default_bid_20_run_double() -> void:
	var opts = GameOptionsScript.new()
	assert_bool(opts.bid_20_run_double).is_false()


# === Friend defaults ===

func test_default_allow_player_friend() -> void:
	var opts = GameOptionsScript.new()
	assert_bool(opts.allow_player_friend).is_true()


func test_default_disallow_fake_friend() -> void:
	var opts = GameOptionsScript.new()
	assert_bool(opts.allow_fake_friend).is_false()


func test_default_allow_last_trick_friend() -> void:
	var opts = GameOptionsScript.new()
	assert_bool(opts.allow_last_trick_friend).is_false()


# === Special Cards defaults ===

func test_default_alter_mighty() -> void:
	var opts = GameOptionsScript.new()
	assert_int(opts.alter_mighty_suit).is_equal(CardScript.Suit.DIAMOND)
	assert_int(opts.alter_mighty_rank).is_equal(CardScript.Rank.ACE)


func test_default_alter_joker_call() -> void:
	var opts = GameOptionsScript.new()
	assert_int(opts.alter_joker_call_suit).is_equal(CardScript.Suit.SPADE)
	assert_int(opts.alter_joker_call_rank).is_equal(CardScript.Rank.THREE)


func test_default_mighty_effects() -> void:
	var opts = GameOptionsScript.new()
	assert_bool(opts.first_trick_mighty_effect).is_true()
	assert_bool(opts.last_trick_mighty_effect).is_true()


func test_default_joker_effects() -> void:
	var opts = GameOptionsScript.new()
	assert_bool(opts.first_trick_joker_effect).is_false()
	assert_bool(opts.last_trick_joker_effect).is_false()


func test_default_joker_called_joker_effect() -> void:
	var opts = GameOptionsScript.new()
	assert_bool(opts.joker_called_joker_effect).is_false()


# === Scoring defaults ===

func test_default_back_run_method() -> void:
	var opts = GameOptionsScript.new()
	assert_int(opts.back_run_method).is_equal(GameOptionsScript.BackRunMethod.RULING_PARTY_10_OR_LESS)


# === Deal Miss defaults ===

func test_default_deal_miss_penalty_method() -> void:
	var opts = GameOptionsScript.new()
	assert_int(opts.deal_miss_penalty_method).is_equal(GameOptionsScript.DealMissPenalty.DOUBLING)


func test_default_deal_miss_doubling_base() -> void:
	var opts = GameOptionsScript.new()
	assert_int(opts.deal_miss_doubling_base).is_equal(2)


func test_default_deal_miss_fixed_penalty() -> void:
	var opts = GameOptionsScript.new()
	assert_int(opts.deal_miss_fixed_penalty).is_equal(5)


func test_default_deal_miss_dealer_to_declarer() -> void:
	var opts = GameOptionsScript.new()
	assert_bool(opts.deal_miss_dealer_to_declarer).is_true()


func test_default_deal_miss_threshold() -> void:
	var opts = GameOptionsScript.new()
	assert_float(opts.deal_miss_threshold).is_equal(1.0)


func test_default_deal_miss_threshold_exclusive() -> void:
	var opts = GameOptionsScript.new()
	assert_int(opts.deal_miss_threshold_type).is_equal(GameOptionsScript.DealMissThreshold.LESS_THAN)


func test_default_deal_miss_card_scores() -> void:
	var opts = GameOptionsScript.new()
	assert_float(opts.deal_miss_joker_score).is_equal(-1.0)
	assert_float(opts.deal_miss_mighty_score).is_equal(0.0)
	assert_float(opts.deal_miss_ten_score).is_equal(0.5)
	assert_float(opts.deal_miss_point_card_score).is_equal(1.0)
	assert_float(opts.deal_miss_non_point_score).is_equal(0.0)


# === Display defaults ===

func test_default_suit_display_style() -> void:
	var opts = GameOptionsScript.new()
	assert_int(opts.suit_display_style).is_equal(GameOptionsScript.SuitDisplay.ENGLISH)


# === Modification ===

func test_modify_min_bid() -> void:
	var opts = GameOptionsScript.new()
	opts.min_bid = 11
	assert_int(opts.min_bid).is_equal(11)


func test_modify_alter_mighty() -> void:
	var opts = GameOptionsScript.new()
	opts.alter_mighty_suit = CardScript.Suit.HEART
	opts.alter_mighty_rank = CardScript.Rank.KING
	assert_int(opts.alter_mighty_suit).is_equal(CardScript.Suit.HEART)
	assert_int(opts.alter_mighty_rank).is_equal(CardScript.Rank.KING)


func test_modify_deal_miss_threshold() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_threshold = 2.0
	opts.deal_miss_threshold_type = GameOptionsScript.DealMissThreshold.LESS_OR_EQUAL
	assert_float(opts.deal_miss_threshold).is_equal(2.0)
	assert_int(opts.deal_miss_threshold_type).is_equal(GameOptionsScript.DealMissThreshold.LESS_OR_EQUAL)

extends GdUnitTestSuite

const PenaltyTableScript = preload("res://scripts/ai/penalty_table.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")

var S := CardScript.Suit.SPADE
var D := CardScript.Suit.DIAMOND
var H := CardScript.Suit.HEART
var C := CardScript.Suit.CLUB
var giruda: int
var empty_used: Array


func before_test() -> void:
	giruda = BiddingStateScript.Giruda.SPADE
	empty_used = [{}, {}, {}, {}]


# --- Mighty ---

func test_mighty_penalty() -> void:
	var mighty = CardScript.new(D, CardScript.Rank.ACE)
	assert_int(PenaltyTableScript.card_usage_penalty(mighty, giruda, empty_used)).is_equal(2001)


# --- Joker tiers ---

func test_joker_default_penalty() -> void:
	var joker = CardScript.create_joker()
	assert_int(PenaltyTableScript.card_usage_penalty(joker, giruda, empty_used)).is_equal(1897)


func test_joker_safe_after_jokercall_used() -> void:
	var joker = CardScript.create_joker()
	var used = [{}, {}, {}, {}]
	PenaltyTableScript.mark_used(CardScript.new(C, CardScript.Rank.THREE), used)
	assert_int(PenaltyTableScript.card_usage_penalty(joker, giruda, used)).is_equal(1898)


func test_joker_last_after_jokercall_and_mighty_used() -> void:
	var joker = CardScript.create_joker()
	var used = [{}, {}, {}, {}]
	PenaltyTableScript.mark_used(CardScript.new(C, CardScript.Rank.THREE), used)
	PenaltyTableScript.mark_used(CardScript.new(D, CardScript.Rank.ACE), used)
	assert_int(PenaltyTableScript.card_usage_penalty(joker, giruda, used)).is_equal(2000)


# --- Jokercall ---

func test_effective_jokercall_penalty() -> void:
	var jc = CardScript.new(C, CardScript.Rank.THREE)
	assert_int(PenaltyTableScript.card_usage_penalty(jc, giruda, empty_used, false)).is_equal(300)


func test_jokercall_opponent_has_joker_normal_penalty() -> void:
	var jc = CardScript.new(C, CardScript.Rank.THREE)
	var p = PenaltyTableScript.card_usage_penalty(jc, giruda, empty_used, true)
	assert_int(p).is_less(300)


# --- Giruda vs normal ---

func test_giruda_score_higher_than_normal_score() -> void:
	var gk = CardScript.new(S, CardScript.Rank.KING)
	var nk = CardScript.new(H, CardScript.Rank.KING)
	assert_int(PenaltyTableScript.card_usage_penalty(gk, giruda, empty_used)).is_greater(
		PenaltyTableScript.card_usage_penalty(nk, giruda, empty_used))


func test_giruda_non_score_higher_than_normal_non_score() -> void:
	var gc = CardScript.new(S, CardScript.Rank.NINE)
	var nc = CardScript.new(H, CardScript.Rank.NINE)
	assert_int(PenaltyTableScript.card_usage_penalty(gc, giruda, empty_used)).is_greater(
		PenaltyTableScript.card_usage_penalty(nc, giruda, empty_used))


# --- Dynamic order: used cards reduce penalty ---

func test_used_higher_cards_reduce_penalty() -> void:
	var card = CardScript.new(H, CardScript.Rank.QUEEN)
	var p_none = PenaltyTableScript.card_usage_penalty(card, giruda, empty_used)
	var used = [{}, {}, {}, {}]
	PenaltyTableScript.mark_used(CardScript.new(H, CardScript.Rank.ACE), used)
	PenaltyTableScript.mark_used(CardScript.new(H, CardScript.Rank.KING), used)
	var p_used = PenaltyTableScript.card_usage_penalty(card, giruda, used)
	assert_int(p_used).is_less(p_none)


# --- Killing penalty ---

func test_killing_penalty_is_negative_half() -> void:
	var card = CardScript.new(H, CardScript.Rank.ACE)
	var usage = PenaltyTableScript.card_usage_penalty(card, giruda, empty_used)
	var kill = PenaltyTableScript.killing_penalty(card, giruda, empty_used)
	assert_int(kill).is_equal(-usage / 2)


# --- Defense lost ---

func test_defense_lost_zero_loss() -> void:
	assert_int(PenaltyTableScript.defense_lost_penalty(5.0, 0.0)).is_equal(0)


func test_defense_lost_normal() -> void:
	assert_int(PenaltyTableScript.defense_lost_penalty(5.0, 2.0)).is_equal(800)


func test_defense_lost_overflow() -> void:
	assert_int(PenaltyTableScript.defense_lost_penalty(0.0, 3.0)).is_equal(100000000)


func test_defense_lost_negative_remain() -> void:
	var result = PenaltyTableScript.defense_lost_penalty(-1.0, 3.0)
	assert_int(result).is_equal(-PenaltyTableScript.attack_gain_penalty(3.0))


# --- Attack gain ---

func test_attack_gain_positive() -> void:
	assert_int(PenaltyTableScript.attack_gain_penalty(2.0)).is_equal(-1500)


func test_attack_gain_zero_or_negative() -> void:
	assert_int(PenaltyTableScript.attack_gain_penalty(0.0)).is_equal(0)
	assert_int(PenaltyTableScript.attack_gain_penalty(-1.0)).is_equal(0)

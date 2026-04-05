extends GdUnitTestSuite

const CardValidatorScript = preload("res://scripts/game_logic/card_validator.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")

var giruda: int
var SA: RefCounted
var DA: RefCounted
var joker: RefCounted


func before_test() -> void:
	giruda = BiddingStateScript.Giruda.SPADE
	SA = CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.ACE)
	DA = CardScript.new(CardScript.Suit.DIAMOND, CardScript.Rank.ACE)
	joker = CardScript.create_joker()


# --- First trick lead restrictions ---

func test_first_trick_cannot_lead_giruda() -> void:
	var hand := [
		CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.TWO),
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.THREE),
	]
	var card = hand[0]
	assert_bool(CardValidatorScript.can_lead(card, hand, giruda, 0)).is_false()


func test_first_trick_cannot_lead_joker() -> void:
	var hand := [joker, CardScript.new(CardScript.Suit.HEART, CardScript.Rank.THREE)]
	assert_bool(CardValidatorScript.can_lead(joker, hand, giruda, 0)).is_false()


func test_first_trick_can_lead_mighty() -> void:
	var hand := [DA, CardScript.new(CardScript.Suit.HEART, CardScript.Rank.THREE)]
	assert_bool(CardValidatorScript.can_lead(DA, hand, giruda, 0)).is_true()


func test_first_trick_can_lead_non_giruda() -> void:
	var hand := [
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.THREE),
		CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.TWO),
	]
	assert_bool(CardValidatorScript.can_lead(hand[0], hand, giruda, 0)).is_true()


func test_first_trick_all_giruda_can_lead_giruda() -> void:
	var hand := []
	for i in range(10):
		hand.append(CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.TWO + i))
	assert_bool(CardValidatorScript.can_lead(hand[0], hand, giruda, 0)).is_true()


func test_first_trick_all_giruda_plus_joker_can_lead_giruda() -> void:
	var hand := []
	for i in range(9):
		hand.append(CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.TWO + i))
	hand.append(joker)
	assert_bool(CardValidatorScript.can_lead(hand[0], hand, giruda, 0)).is_true()


func test_first_trick_giruda_plus_mighty_must_lead_mighty() -> void:
	var hand := []
	for i in range(9):
		hand.append(CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.TWO + i))
	hand.append(DA)
	assert_bool(CardValidatorScript.can_lead(hand[0], hand, giruda, 0)).is_false()
	assert_bool(CardValidatorScript.can_lead(DA, hand, giruda, 0)).is_true()


func test_non_first_trick_can_lead_giruda() -> void:
	var hand := [
		CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.TWO),
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.THREE),
	]
	assert_bool(CardValidatorScript.can_lead(hand[0], hand, giruda, 1)).is_true()


# --- Suit follow rules ---

func test_must_follow_lead_suit() -> void:
	var hand := [
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.TWO),
		CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.THREE),
	]
	var lead_suit = CardScript.Suit.HEART
	assert_bool(CardValidatorScript.can_follow(hand[0], hand, lead_suit, giruda, false)).is_true()
	assert_bool(CardValidatorScript.can_follow(hand[1], hand, lead_suit, giruda, false)).is_false()


func test_no_lead_suit_can_play_anything() -> void:
	var hand := [
		CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.THREE),
		CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.FIVE),
	]
	var lead_suit = CardScript.Suit.HEART
	assert_bool(CardValidatorScript.can_follow(hand[0], hand, lead_suit, giruda, false)).is_true()
	assert_bool(CardValidatorScript.can_follow(hand[1], hand, lead_suit, giruda, false)).is_true()


func test_mighty_can_always_follow() -> void:
	var hand := [
		SA,
		CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.THREE),
	]
	var lead_suit = CardScript.Suit.HEART
	assert_bool(CardValidatorScript.can_follow(SA, hand, lead_suit, giruda, false)).is_true()


func test_joker_can_always_follow() -> void:
	var hand := [
		joker,
		CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.THREE),
	]
	var lead_suit = CardScript.Suit.HEART
	assert_bool(CardValidatorScript.can_follow(joker, hand, lead_suit, giruda, false)).is_true()


func test_mighty_bound_to_own_suit_follow() -> void:
	var hand := [SA]
	var lead_suit = CardScript.Suit.SPADE
	assert_bool(CardValidatorScript.can_follow(SA, hand, lead_suit, giruda, false)).is_true()


func test_mighty_only_spade_must_play_when_spade_led() -> void:
	var hand := [
		SA,
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.THREE),
	]
	var lead_suit = CardScript.Suit.SPADE
	assert_bool(CardValidatorScript.can_follow(hand[1], hand, lead_suit, giruda, false)).is_false()


# --- Joker call ---

func test_joker_call_forces_joker() -> void:
	var hand := [
		joker,
		CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.FIVE),
	]
	var lead_suit = CardScript.Suit.CLUB
	assert_bool(CardValidatorScript.can_follow(hand[1], hand, lead_suit, giruda, true)).is_false()
	assert_bool(CardValidatorScript.can_follow(joker, hand, lead_suit, giruda, true)).is_true()


func test_joker_call_mighty_can_substitute() -> void:
	var hand := [joker, DA]
	var lead_suit = CardScript.Suit.CLUB
	assert_bool(CardValidatorScript.can_follow(DA, hand, lead_suit, giruda, true)).is_true()


# --- Custom alter mighty ---

func test_default_mighty_spade_ace() -> void:
	assert_bool(CardValidatorScript.is_mighty(SA, BiddingStateScript.Giruda.HEART)).is_true()


func test_default_alter_mighty_diamond_ace_when_spade_giruda() -> void:
	assert_bool(CardValidatorScript.is_mighty(DA, BiddingStateScript.Giruda.SPADE)).is_true()
	assert_bool(CardValidatorScript.is_mighty(SA, BiddingStateScript.Giruda.SPADE)).is_false()


func test_custom_alter_mighty() -> void:
	var opts = GameOptionsScript.new()
	opts.alter_mighty_suit = CardScript.Suit.HEART
	opts.alter_mighty_rank = CardScript.Rank.KING
	var HK = CardScript.new(CardScript.Suit.HEART, CardScript.Rank.KING)
	# When spade giruda, default alter mighty (DA) should no longer be mighty
	assert_bool(CardValidatorScript.is_mighty_with_options(DA, BiddingStateScript.Giruda.SPADE, opts)).is_false()
	# HK should be mighty instead
	assert_bool(CardValidatorScript.is_mighty_with_options(HK, BiddingStateScript.Giruda.SPADE, opts)).is_true()
	# SA still mighty for non-spade giruda
	assert_bool(CardValidatorScript.is_mighty_with_options(SA, BiddingStateScript.Giruda.HEART, opts)).is_true()


func test_custom_alter_mighty_when_alter_is_giruda() -> void:
	# alter mighty is Heart King, giruda is Heart => alter mighty activates
	var opts = GameOptionsScript.new()
	opts.alter_mighty_suit = CardScript.Suit.DIAMOND
	opts.alter_mighty_rank = CardScript.Rank.KING
	var DK = CardScript.new(CardScript.Suit.DIAMOND, CardScript.Rank.KING)
	# Spade A is default mighty, but giruda is spade => use alter
	assert_bool(CardValidatorScript.is_mighty_with_options(SA, BiddingStateScript.Giruda.SPADE, opts)).is_false()
	assert_bool(CardValidatorScript.is_mighty_with_options(DK, BiddingStateScript.Giruda.SPADE, opts)).is_true()

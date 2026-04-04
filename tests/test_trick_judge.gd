extends GdUnitTestSuite

const TrickJudgeScript = preload("res://scripts/game_logic/trick_judge.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")

var giruda: int
var S := CardScript.Suit.SPADE
var D := CardScript.Suit.DIAMOND
var H := CardScript.Suit.HEART
var C := CardScript.Suit.CLUB


func before_test() -> void:
	giruda = BiddingStateScript.Giruda.SPADE


func _card(suit: int, rank: int) -> RefCounted:
	return CardScript.new(suit, rank)


func _joker() -> RefCounted:
	return CardScript.create_joker()


# --- Mighty wins everything ---

func test_mighty_wins() -> void:
	var trick := [_card(H, CardScript.Rank.ACE), _card(D, CardScript.Rank.ACE)]
	var players := [0, 1]
	assert_int(TrickJudgeScript.determine_winner(trick, players, H, giruda, 1, false)).is_equal(1)


func test_mighty_beats_joker() -> void:
	var trick := [_joker(), _card(D, CardScript.Rank.ACE)]
	var players := [0, 1]
	assert_int(TrickJudgeScript.determine_winner(trick, players, H, giruda, 1, false)).is_equal(1)


# --- Valid joker beats everything except mighty ---

func test_joker_beats_giruda_ace() -> void:
	var trick := [_card(S, CardScript.Rank.ACE), _joker()]
	var players := [0, 1]
	assert_int(TrickJudgeScript.determine_winner(trick, players, S, giruda, 1, false)).is_equal(1)


func test_joker_nullified_first_trick() -> void:
	var trick := [_card(H, CardScript.Rank.TWO), _joker()]
	var players := [0, 1]
	assert_int(TrickJudgeScript.determine_winner(trick, players, H, giruda, 0, false)).is_equal(0)


func test_joker_nullified_last_trick() -> void:
	var trick := [_card(H, CardScript.Rank.TWO), _joker()]
	var players := [0, 1]
	assert_int(TrickJudgeScript.determine_winner(trick, players, H, giruda, 9, false)).is_equal(0)


func test_joker_nullified_by_joker_call() -> void:
	var trick := [_card(C, CardScript.Rank.THREE), _joker(), _card(C, CardScript.Rank.ACE)]
	var players := [0, 1, 2]
	assert_int(TrickJudgeScript.determine_winner(trick, players, C, giruda, 3, true)).is_equal(2)


# --- Giruda beats non-giruda ---

func test_giruda_beats_lead_suit() -> void:
	var trick := [_card(H, CardScript.Rank.ACE), _card(S, CardScript.Rank.TWO)]
	var players := [0, 1]
	assert_int(TrickJudgeScript.determine_winner(trick, players, H, giruda, 1, false)).is_equal(1)


func test_higher_giruda_wins() -> void:
	var trick := [_card(H, CardScript.Rank.ACE), _card(S, CardScript.Rank.TWO), _card(S, CardScript.Rank.KING)]
	var players := [0, 1, 2]
	assert_int(TrickJudgeScript.determine_winner(trick, players, H, giruda, 1, false)).is_equal(2)


# --- Lead suit ---

func test_lead_suit_higher_rank_wins() -> void:
	var trick := [_card(H, CardScript.Rank.TEN), _card(H, CardScript.Rank.ACE)]
	var players := [0, 1]
	assert_int(TrickJudgeScript.determine_winner(trick, players, H, giruda, 1, false)).is_equal(1)


func test_off_suit_loses_to_lead_suit() -> void:
	var trick := [_card(H, CardScript.Rank.TWO), _card(C, CardScript.Rank.ACE)]
	var players := [0, 1]
	assert_int(TrickJudgeScript.determine_winner(trick, players, H, giruda, 1, false)).is_equal(0)


# --- No giruda ---

func test_no_giruda_lead_suit_wins() -> void:
	var ng = BiddingStateScript.Giruda.NO_GIRUDA
	var trick := [_card(H, CardScript.Rank.TEN), _card(H, CardScript.Rank.ACE), _card(C, CardScript.Rank.ACE)]
	var players := [0, 1, 2]
	assert_int(TrickJudgeScript.determine_winner(trick, players, H, ng, 1, false)).is_equal(1)


# --- Nullified joker is weakest ---

func test_nullified_joker_loses_to_off_suit() -> void:
	var trick := [_card(C, CardScript.Rank.THREE), _joker(), _card(D, CardScript.Rank.TWO)]
	var players := [0, 1, 2]
	assert_int(TrickJudgeScript.determine_winner(trick, players, C, giruda, 3, true)).is_equal(0)


# --- Five player trick ---

func test_five_player_trick() -> void:
	var trick := [
		_card(H, CardScript.Rank.KING),
		_card(H, CardScript.Rank.TWO),
		_card(S, CardScript.Rank.THREE),
		_card(D, CardScript.Rank.QUEEN),
		_card(H, CardScript.Rank.ACE),
	]
	var players := [0, 1, 2, 3, 4]
	assert_int(TrickJudgeScript.determine_winner(trick, players, H, giruda, 1, false)).is_equal(2)

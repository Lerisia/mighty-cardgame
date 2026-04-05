extends GdUnitTestSuite

const FriendSelectorScript = preload("res://scripts/ai/friend_selector.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")

var S := CardScript.Suit.SPADE
var D := CardScript.Suit.DIAMOND
var H := CardScript.Suit.HEART
var C := CardScript.Suit.CLUB


func _card(suit: int, rank: int):
	return CardScript.new(suit, rank)


func test_picks_mighty_if_not_in_hand() -> void:
	var hand := []
	for i in range(10):
		hand.append(_card(S, CardScript.Rank.TWO + i))
	var result = FriendSelectorScript.select(hand, BiddingStateScript.Giruda.SPADE)
	assert_int(result["type"]).is_equal(DeclarerPhaseScript.FriendCallType.CARD)
	assert_int(result["card"].suit).is_equal(D)
	assert_int(result["card"].rank).is_equal(CardScript.Rank.ACE)


func test_skips_mighty_if_in_hand() -> void:
	var hand := [_card(D, CardScript.Rank.ACE)]
	for i in range(9):
		hand.append(_card(S, CardScript.Rank.TWO + i))
	var result = FriendSelectorScript.select(hand, BiddingStateScript.Giruda.SPADE)
	assert_bool(result["card"].suit == D and result["card"].rank == CardScript.Rank.ACE).is_false()


func test_picks_joker_if_mighty_in_hand() -> void:
	var hand := [_card(D, CardScript.Rank.ACE)]
	for i in range(9):
		hand.append(_card(H, CardScript.Rank.TWO + i))
	var result = FriendSelectorScript.select(hand, BiddingStateScript.Giruda.SPADE)
	assert_bool(result["card"].is_joker).is_true()


func test_picks_giruda_ace_if_mighty_and_joker_in_hand() -> void:
	var hand := [_card(D, CardScript.Rank.ACE), CardScript.create_joker()]
	for i in range(8):
		hand.append(_card(H, CardScript.Rank.TWO + i))
	var result = FriendSelectorScript.select(hand, BiddingStateScript.Giruda.SPADE)
	assert_int(result["card"].suit).is_equal(S)
	assert_int(result["card"].rank).is_equal(CardScript.Rank.ACE)


func test_picks_giruda_king_if_giruda_ace_in_hand() -> void:
	var hand := [_card(D, CardScript.Rank.ACE), CardScript.create_joker(), _card(S, CardScript.Rank.ACE)]
	for i in range(7):
		hand.append(_card(H, CardScript.Rank.TWO + i))
	var result = FriendSelectorScript.select(hand, BiddingStateScript.Giruda.SPADE)
	assert_int(result["card"].suit).is_equal(S)
	assert_int(result["card"].rank).is_equal(CardScript.Rank.KING)


func test_no_friend_when_all_strong_cards_in_hand() -> void:
	var hand := [
		_card(D, CardScript.Rank.ACE),
		CardScript.create_joker(),
		_card(S, CardScript.Rank.ACE),
		_card(H, CardScript.Rank.ACE),
		_card(C, CardScript.Rank.ACE),
		_card(S, CardScript.Rank.KING),
		_card(S, CardScript.Rank.QUEEN),
	]
	for i in range(3):
		hand.append(_card(H, CardScript.Rank.TWO + i))
	var result = FriendSelectorScript.select(hand, BiddingStateScript.Giruda.SPADE)
	assert_int(result["type"]).is_equal(DeclarerPhaseScript.FriendCallType.NO_FRIEND)

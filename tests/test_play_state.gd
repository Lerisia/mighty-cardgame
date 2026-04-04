extends GdUnitTestSuite

const PlayStateScript = preload("res://scripts/game_logic/play_state.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")


func _make_hand() -> Array:
	var hand := []
	for i in range(10):
		hand.append(CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.TWO + i))
	return hand


func test_initial_state() -> void:
	var state = PlayStateScript.new()
	assert_int(state.role).is_equal(PlayStateScript.Role.OPPOSITION)
	assert_int(state.hand.size()).is_equal(0)
	assert_int(state.point_cards.size()).is_equal(0)
	assert_int(state.discarded.size()).is_equal(0)
	assert_object(state.friend_call_card).is_null()
	assert_object(state.friend_reveal_card).is_null()
	assert_bool(state.friend_revealed).is_false()


func test_set_hand() -> void:
	var state = PlayStateScript.new()
	var hand = _make_hand()
	state.hand = hand
	assert_int(state.hand.size()).is_equal(10)


func test_play_card_removes_from_hand() -> void:
	var state = PlayStateScript.new()
	state.hand = _make_hand()
	var card = state.hand[0]
	state.play_card(card)
	assert_int(state.hand.size()).is_equal(9)
	assert_bool(state.hand.has(card)).is_false()


func test_play_card_not_in_hand_returns_false() -> void:
	var state = PlayStateScript.new()
	state.hand = _make_hand()
	var other_card = CardScript.new(CardScript.Suit.HEART, CardScript.Rank.ACE)
	assert_bool(state.play_card(other_card)).is_false()
	assert_int(state.hand.size()).is_equal(10)


func test_add_point_cards_filters() -> void:
	var state = PlayStateScript.new()
	var trick := [
		CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.ACE),
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.TWO),
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.KING),
		CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.FIVE),
		CardScript.new(CardScript.Suit.DIAMOND, CardScript.Rank.TEN),
	]
	state.add_point_cards(trick)
	assert_int(state.point_cards.size()).is_equal(3)


func test_get_point_count() -> void:
	var state = PlayStateScript.new()
	var trick := [
		CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.ACE),
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.TWO),
	]
	state.add_point_cards(trick)
	assert_int(state.get_point_count()).is_equal(1)


func test_declarer_discard() -> void:
	var state = PlayStateScript.new()
	state.role = PlayStateScript.Role.DECLARER
	var cards := [
		CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.TWO),
		CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.THREE),
		CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.FOUR),
	]
	state.set_discarded(cards)
	assert_int(state.discarded.size()).is_equal(3)


func test_friend_call_card() -> void:
	var state = PlayStateScript.new()
	state.role = PlayStateScript.Role.DECLARER
	var call_card = CardScript.new(CardScript.Suit.HEART, CardScript.Rank.ACE)
	state.friend_call_card = call_card
	assert_str(state.friend_call_card.to_string()).is_equal("HA")


func test_friend_reveal_card() -> void:
	var state = PlayStateScript.new()
	state.role = PlayStateScript.Role.FRIEND
	var reveal_card = CardScript.new(CardScript.Suit.HEART, CardScript.Rank.ACE)
	state.friend_reveal_card = reveal_card
	assert_str(state.friend_reveal_card.to_string()).is_equal("HA")
	assert_bool(state.friend_revealed).is_false()


func test_friend_revealed_on_play() -> void:
	var state = PlayStateScript.new()
	state.role = PlayStateScript.Role.FRIEND
	var reveal_card = CardScript.new(CardScript.Suit.HEART, CardScript.Rank.ACE)
	state.friend_reveal_card = reveal_card
	state.hand = [reveal_card, CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.TWO)]
	state.play_card(reveal_card)
	assert_bool(state.friend_revealed).is_true()


func test_role_assignment() -> void:
	var state = PlayStateScript.new()
	state.role = PlayStateScript.Role.DECLARER
	assert_int(state.role).is_equal(PlayStateScript.Role.DECLARER)
	state.role = PlayStateScript.Role.FRIEND
	assert_int(state.role).is_equal(PlayStateScript.Role.FRIEND)
	state.role = PlayStateScript.Role.OPPOSITION
	assert_int(state.role).is_equal(PlayStateScript.Role.OPPOSITION)

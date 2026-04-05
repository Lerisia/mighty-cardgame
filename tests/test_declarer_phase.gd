extends GdUnitTestSuite

const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")
const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")


func _make_phase(bid: int = 13, giruda: int = BiddingStateScript.Giruda.SPADE) -> RefCounted:
	var hand := []
	for i in range(10):
		hand.append(CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.TWO + i))
	var kitty := [
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.TWO),
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.THREE),
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.FOUR),
	]
	return DeclarerPhaseScript.new(hand, kitty, bid, giruda)


func test_initial_state() -> void:
	var phase = _make_phase()
	assert_int(phase.hand.size()).is_equal(10)
	assert_int(phase.kitty.size()).is_equal(3)
	assert_int(phase.bid).is_equal(13)
	assert_int(phase.giruda).is_equal(BiddingStateScript.Giruda.SPADE)
	assert_bool(phase.first_change_used).is_false()
	assert_bool(phase.kitty_revealed).is_false()


func test_first_giruda_change() -> void:
	var phase = _make_phase(13, BiddingStateScript.Giruda.SPADE)
	assert_bool(phase.change_giruda_first(BiddingStateScript.Giruda.HEART, 14)).is_true()
	assert_int(phase.giruda).is_equal(BiddingStateScript.Giruda.HEART)
	assert_int(phase.bid).is_equal(14)
	assert_bool(phase.first_change_used).is_true()


func test_first_change_to_no_giruda_no_raise() -> void:
	var phase = _make_phase(13, BiddingStateScript.Giruda.SPADE)
	assert_bool(phase.change_giruda_first(BiddingStateScript.Giruda.NO_GIRUDA, 13)).is_true()
	assert_int(phase.giruda).is_equal(BiddingStateScript.Giruda.NO_GIRUDA)
	assert_int(phase.bid).is_equal(13)


func test_first_change_insufficient_raise_rejected() -> void:
	var phase = _make_phase(13, BiddingStateScript.Giruda.SPADE)
	assert_bool(phase.change_giruda_first(BiddingStateScript.Giruda.HEART, 13)).is_false()


func test_first_change_cannot_be_used_twice() -> void:
	var phase = _make_phase(13, BiddingStateScript.Giruda.SPADE)
	phase.change_giruda_first(BiddingStateScript.Giruda.HEART, 14)
	assert_bool(phase.change_giruda_first(BiddingStateScript.Giruda.CLUB, 15)).is_false()


func test_skip_first_change() -> void:
	var phase = _make_phase()
	phase.skip_first_change()
	assert_bool(phase.first_change_used).is_true()


func test_reveal_kitty() -> void:
	var phase = _make_phase()
	phase.skip_first_change()
	phase.reveal_kitty()
	assert_bool(phase.kitty_revealed).is_true()
	assert_int(phase.hand.size()).is_equal(13)


func test_reveal_kitty_requires_first_change_done() -> void:
	var phase = _make_phase()
	phase.reveal_kitty()
	assert_bool(phase.kitty_revealed).is_false()


func test_second_giruda_change() -> void:
	var phase = _make_phase(13, BiddingStateScript.Giruda.SPADE)
	phase.skip_first_change()
	phase.reveal_kitty()
	assert_bool(phase.change_giruda_second(BiddingStateScript.Giruda.HEART, 15)).is_true()
	assert_int(phase.giruda).is_equal(BiddingStateScript.Giruda.HEART)
	assert_int(phase.bid).is_equal(15)


func test_second_change_to_no_giruda_raise_one() -> void:
	var phase = _make_phase(13, BiddingStateScript.Giruda.SPADE)
	phase.skip_first_change()
	phase.reveal_kitty()
	assert_bool(phase.change_giruda_second(BiddingStateScript.Giruda.NO_GIRUDA, 14)).is_true()


func test_second_change_insufficient_raise_rejected() -> void:
	var phase = _make_phase(13, BiddingStateScript.Giruda.SPADE)
	phase.skip_first_change()
	phase.reveal_kitty()
	assert_bool(phase.change_giruda_second(BiddingStateScript.Giruda.HEART, 14)).is_false()


func test_finalize_with_card_friend() -> void:
	var phase = _make_phase()
	phase.skip_first_change()
	phase.reveal_kitty()
	var to_discard := [phase.hand[0], phase.hand[1], phase.hand[2]]
	var friend_card = CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.ACE)
	var friend_call := {
		"type": DeclarerPhaseScript.FriendCallType.CARD,
		"card": friend_card,
	}
	assert_bool(phase.finalize(to_discard, friend_call)).is_true()
	assert_int(phase.hand.size()).is_equal(10)
	assert_int(phase.discarded.size()).is_equal(3)
	assert_int(phase.friend_call_type).is_equal(DeclarerPhaseScript.FriendCallType.CARD)
	assert_str(phase.friend_call_card.to_string()).is_equal("SA")
	assert_bool(phase.is_finished).is_true()


func test_finalize_with_no_friend() -> void:
	var phase = _make_phase()
	phase.skip_first_change()
	phase.reveal_kitty()
	var to_discard := [phase.hand[0], phase.hand[1], phase.hand[2]]
	var friend_call := {
		"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND,
	}
	assert_bool(phase.finalize(to_discard, friend_call)).is_true()
	assert_int(phase.friend_call_type).is_equal(DeclarerPhaseScript.FriendCallType.NO_FRIEND)


func test_finalize_with_first_trick_winner() -> void:
	var phase = _make_phase()
	phase.skip_first_change()
	phase.reveal_kitty()
	var to_discard := [phase.hand[0], phase.hand[1], phase.hand[2]]
	var friend_call := {
		"type": DeclarerPhaseScript.FriendCallType.FIRST_TRICK_WINNER,
	}
	assert_bool(phase.finalize(to_discard, friend_call)).is_true()
	assert_int(phase.friend_call_type).is_equal(DeclarerPhaseScript.FriendCallType.FIRST_TRICK_WINNER)


func test_finalize_with_player_friend() -> void:
	var phase = _make_phase()
	phase.skip_first_change()
	phase.reveal_kitty()
	var to_discard := [phase.hand[0], phase.hand[1], phase.hand[2]]
	var friend_call := {
		"type": DeclarerPhaseScript.FriendCallType.PLAYER,
		"player_index": 3,
	}
	assert_bool(phase.finalize(to_discard, friend_call)).is_true()
	assert_int(phase.friend_call_type).is_equal(DeclarerPhaseScript.FriendCallType.PLAYER)
	assert_int(phase.friend_call_player).is_equal(3)


func test_finalize_wrong_count_rejected() -> void:
	var phase = _make_phase()
	phase.skip_first_change()
	phase.reveal_kitty()
	var to_discard := [phase.hand[0], phase.hand[1]]
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	assert_bool(phase.finalize(to_discard, friend_call)).is_false()


# --- Options: giruda change restrictions ---

func _make_phase_with_options(bid: int, giruda: int, opts: GameOptionsScript) -> RefCounted:
	var hand := []
	for i in range(10):
		hand.append(CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.TWO + i))
	var kitty := [
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.TWO),
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.THREE),
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.FOUR),
	]
	return DeclarerPhaseScript.new(hand, kitty, bid, giruda, opts)


func test_disallow_giruda_change_before_kitty() -> void:
	var opts = GameOptionsScript.new()
	opts.allow_giruda_change_before_kitty = false
	var phase = _make_phase_with_options(13, BiddingStateScript.Giruda.SPADE, opts)
	assert_bool(phase.change_giruda_first(BiddingStateScript.Giruda.HEART, 14)).is_false()


func test_disallow_giruda_change_after_kitty() -> void:
	var opts = GameOptionsScript.new()
	opts.allow_giruda_change_after_kitty = false
	var phase = _make_phase_with_options(13, BiddingStateScript.Giruda.SPADE, opts)
	phase.skip_first_change()
	phase.reveal_kitty()
	assert_bool(phase.change_giruda_second(BiddingStateScript.Giruda.HEART, 15)).is_false()


func test_disallow_player_friend() -> void:
	var opts = GameOptionsScript.new()
	opts.allow_player_friend = false
	var phase = _make_phase_with_options(13, BiddingStateScript.Giruda.SPADE, opts)
	phase.skip_first_change()
	phase.reveal_kitty()
	var to_discard := [phase.hand[0], phase.hand[1], phase.hand[2]]
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.PLAYER, "player_index": 3}
	assert_bool(phase.finalize(to_discard, friend_call)).is_false()


func test_allow_player_friend_default() -> void:
	var opts = GameOptionsScript.new()
	var phase = _make_phase_with_options(13, BiddingStateScript.Giruda.SPADE, opts)
	phase.skip_first_change()
	phase.reveal_kitty()
	var to_discard := [phase.hand[0], phase.hand[1], phase.hand[2]]
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.PLAYER, "player_index": 3}
	assert_bool(phase.finalize(to_discard, friend_call)).is_true()


# --- Fake friend restriction ---

func test_fake_friend_allowed_by_default() -> void:
	var opts = GameOptionsScript.new()
	var phase = _make_phase_with_options(13, BiddingStateScript.Giruda.SPADE, opts)
	phase.skip_first_change()
	phase.reveal_kitty()
	# Call a card that is in own hand as friend
	var friend_card = phase.hand[3]
	var to_discard := [phase.hand[0], phase.hand[1], phase.hand[2]]
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.CARD, "card": friend_card}
	assert_bool(phase.finalize(to_discard, friend_call)).is_true()


func test_fake_friend_own_hand_rejected() -> void:
	var opts = GameOptionsScript.new()
	opts.allow_fake_friend = false
	var phase = _make_phase_with_options(13, BiddingStateScript.Giruda.SPADE, opts)
	phase.skip_first_change()
	phase.reveal_kitty()
	# Call a card that remains in own hand after discard
	var friend_card = phase.hand[5]
	var to_discard := [phase.hand[0], phase.hand[1], phase.hand[2]]
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.CARD, "card": friend_card}
	assert_bool(phase.finalize(to_discard, friend_call)).is_false()


func test_fake_friend_discarded_card_rejected() -> void:
	var opts = GameOptionsScript.new()
	opts.allow_fake_friend = false
	var phase = _make_phase_with_options(13, BiddingStateScript.Giruda.SPADE, opts)
	phase.skip_first_change()
	phase.reveal_kitty()
	# Call a card that is being discarded
	var friend_card = phase.hand[0]
	var to_discard := [phase.hand[0], phase.hand[1], phase.hand[2]]
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.CARD, "card": friend_card}
	assert_bool(phase.finalize(to_discard, friend_call)).is_false()


func test_fake_friend_other_card_allowed() -> void:
	var opts = GameOptionsScript.new()
	opts.allow_fake_friend = false
	var phase = _make_phase_with_options(13, BiddingStateScript.Giruda.SPADE, opts)
	phase.skip_first_change()
	phase.reveal_kitty()
	# Call a card NOT in hand or discard
	var friend_card = CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.ACE)
	var to_discard := [phase.hand[0], phase.hand[1], phase.hand[2]]
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.CARD, "card": friend_card}
	assert_bool(phase.finalize(to_discard, friend_call)).is_true()

func test_finalize_requires_kitty_revealed() -> void:
	var phase = _make_phase()
	phase.skip_first_change()
	var to_discard := [phase.hand[0], phase.hand[1], phase.hand[2]]
	var friend_call := {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}
	assert_bool(phase.finalize(to_discard, friend_call)).is_false()

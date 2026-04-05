extends GdUnitTestSuite

const DealMissScript = preload("res://scripts/game_logic/deal_miss.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")
const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")


func test_mighty_scores_zero() -> void:
	var sa = CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.ACE)
	assert_float(DealMissScript.card_score(sa)).is_equal(0.0)


func test_ten_scores_half() -> void:
	var card = CardScript.new(CardScript.Suit.HEART, CardScript.Rank.TEN)
	assert_float(DealMissScript.card_score(card)).is_equal(0.5)


func test_joker_scores_negative_one() -> void:
	var joker = CardScript.create_joker()
	assert_float(DealMissScript.card_score(joker)).is_equal(-1.0)


func test_point_card_scores_one() -> void:
	for rank in [CardScript.Rank.KING, CardScript.Rank.QUEEN, CardScript.Rank.JACK]:
		var card = CardScript.new(CardScript.Suit.HEART, rank)
		assert_float(DealMissScript.card_score(card)).is_equal(1.0)


func test_ace_non_mighty_scores_one() -> void:
	var ha = CardScript.new(CardScript.Suit.HEART, CardScript.Rank.ACE)
	assert_float(DealMissScript.card_score(ha)).is_equal(1.0)


func test_non_point_card_scores_zero() -> void:
	var card = CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.FIVE)
	assert_float(DealMissScript.card_score(card)).is_equal(0.0)


func test_hand_eligible_for_deal_miss() -> void:
	var hand := []
	for i in range(8):
		hand.append(CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.TWO + i))
	hand.append(CardScript.create_joker())
	hand.append(CardScript.new(CardScript.Suit.DIAMOND, CardScript.Rank.TWO))
	assert_bool(DealMissScript.can_declare(hand)).is_true()


func test_hand_not_eligible() -> void:
	var hand := [
		CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.ACE),
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.KING),
		CardScript.new(CardScript.Suit.HEART, CardScript.Rank.QUEEN),
	]
	for i in range(7):
		hand.append(CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.TWO + i))
	assert_bool(DealMissScript.can_declare(hand)).is_false()


func test_hand_exactly_half_point_eligible() -> void:
	var hand := []
	for i in range(8):
		hand.append(CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.TWO + i))
	hand.append(CardScript.new(CardScript.Suit.DIAMOND, CardScript.Rank.TWO))
	hand.append(CardScript.new(CardScript.Suit.HEART, CardScript.Rank.TEN))
	assert_float(DealMissScript.hand_score(hand)).is_equal(0.5)
	assert_bool(DealMissScript.can_declare(hand)).is_true()


func test_hand_exactly_one_point_not_eligible() -> void:
	var hand := []
	for i in range(8):
		hand.append(CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.TWO + i))
	hand.append(CardScript.new(CardScript.Suit.DIAMOND, CardScript.Rank.TWO))
	hand.append(CardScript.new(CardScript.Suit.HEART, CardScript.Rank.JACK))
	assert_float(DealMissScript.hand_score(hand)).is_equal(1.0)
	assert_bool(DealMissScript.can_declare(hand)).is_false()


# --- Options-based deal miss ---

func test_custom_card_scores() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_ten_score = 1.0
	opts.deal_miss_joker_score = 0.0
	var ten = CardScript.new(CardScript.Suit.HEART, CardScript.Rank.TEN)
	var joker_card = CardScript.create_joker()
	assert_float(DealMissScript.card_score_with_options(ten, opts)).is_equal(1.0)
	assert_float(DealMissScript.card_score_with_options(joker_card, opts)).is_equal(0.0)


func test_custom_threshold_less_or_equal() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_threshold = 1.0
	opts.deal_miss_threshold_type = GameOptionsScript.DealMissThreshold.LESS_OR_EQUAL
	# hand with exactly 1.0 score should now qualify
	var hand := []
	for i in range(8):
		hand.append(CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.TWO + i))
	hand.append(CardScript.new(CardScript.Suit.DIAMOND, CardScript.Rank.TWO))
	hand.append(CardScript.new(CardScript.Suit.HEART, CardScript.Rank.JACK))
	assert_float(DealMissScript.hand_score_with_options(hand, opts)).is_equal(1.0)
	assert_bool(DealMissScript.can_declare_with_options(hand, opts)).is_true()


func test_custom_higher_threshold() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_threshold = 3.0
	opts.deal_miss_threshold_type = GameOptionsScript.DealMissThreshold.LESS_THAN
	# hand with 2 point cards (score 2.0) should qualify
	var hand := []
	for i in range(8):
		hand.append(CardScript.new(CardScript.Suit.CLUB, CardScript.Rank.TWO + i))
	hand.append(CardScript.new(CardScript.Suit.HEART, CardScript.Rank.JACK))
	hand.append(CardScript.new(CardScript.Suit.HEART, CardScript.Rank.QUEEN))
	assert_float(DealMissScript.hand_score_with_options(hand, opts)).is_equal(2.0)
	assert_bool(DealMissScript.can_declare_with_options(hand, opts)).is_true()


func test_custom_mighty_score() -> void:
	var opts = GameOptionsScript.new()
	opts.deal_miss_mighty_score = 2.0
	var sa = CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.ACE)
	assert_float(DealMissScript.card_score_with_options(sa, opts)).is_equal(2.0)

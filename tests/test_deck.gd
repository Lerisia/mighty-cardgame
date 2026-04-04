extends GdUnitTestSuite

const DeckScript = preload("res://scripts/game_logic/deck.gd")


func test_deck_has_53_cards() -> void:
	var deck = DeckScript.new()
	assert_int(deck.cards.size()).is_equal(53)


func test_deck_has_one_joker() -> void:
	var deck = DeckScript.new()
	var joker_count := 0
	for card in deck.cards:
		if card.is_joker:
			joker_count += 1
	assert_int(joker_count).is_equal(1)


func test_deck_has_13_cards_per_suit() -> void:
	var deck = DeckScript.new()
	var CardScript = preload("res://scripts/game_logic/card.gd")
	for suit in CardScript.Suit.values():
		var count := 0
		for card in deck.cards:
			if not card.is_joker and card.suit == suit:
				count += 1
		assert_int(count).is_equal(13)


func test_deck_no_duplicates() -> void:
	var deck = DeckScript.new()
	var seen := {}
	for card in deck.cards:
		var key = card.to_string()
		assert_bool(seen.has(key)).is_false()
		seen[key] = true


func test_deal_five_players() -> void:
	var deck = DeckScript.new()
	var result = deck.deal(5)
	assert_int(result["hands"].size()).is_equal(5)
	for hand in result["hands"]:
		assert_int(hand.size()).is_equal(10)
	assert_int(result["kitty"].size()).is_equal(3)


func test_deal_uses_all_53_cards() -> void:
	var deck = DeckScript.new()
	var result = deck.deal(5)
	var total := 0
	for hand in result["hands"]:
		total += hand.size()
	total += result["kitty"].size()
	assert_int(total).is_equal(53)


func test_shuffle_changes_order() -> void:
	var deck1 = DeckScript.new()
	var deck2 = DeckScript.new()
	deck2.shuffle()
	var same_count := 0
	for i in range(deck1.cards.size()):
		if deck1.cards[i].to_string() == deck2.cards[i].to_string():
			same_count += 1
	assert_bool(same_count < 53).is_true()

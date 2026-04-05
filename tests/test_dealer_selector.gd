extends GdUnitTestSuite

const DealerSelectorScript = preload("res://scripts/game_logic/dealer_selector.gd")


func test_first_game_random() -> void:
	var result = DealerSelectorScript.first_game(5)
	assert_int(result).is_greater_equal(0)
	assert_int(result).is_less(5)


func test_ruling_party_wins_declarer_is_dealer() -> void:
	var result = DealerSelectorScript.next_dealer(true, 2, 4)
	assert_int(result).is_equal(2)


func test_opposition_wins_friend_is_dealer() -> void:
	var result = DealerSelectorScript.next_dealer(false, 2, 4)
	assert_int(result).is_equal(4)


func test_opposition_wins_no_friend_declarer_is_dealer() -> void:
	var result = DealerSelectorScript.next_dealer(false, 2, -1)
	assert_int(result).is_equal(2)


func test_ruling_party_wins_no_friend_declarer_is_dealer() -> void:
	var result = DealerSelectorScript.next_dealer(true, 3, -1)
	assert_int(result).is_equal(3)

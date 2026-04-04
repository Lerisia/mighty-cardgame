extends GdUnitTestSuite

const PlayerScript = preload("res://scripts/game_logic/player.gd")


func test_create_player() -> void:
	var player = PlayerScript.new("Alice", 1)
	assert_str(player.player_name).is_equal("Alice")
	assert_int(player.id).is_equal(1)
	assert_bool(player.is_bot).is_false()
	assert_int(player.score).is_equal(0)


func test_create_bot_player() -> void:
	var player = PlayerScript.new("Bot1", 2, true)
	assert_bool(player.is_bot).is_true()


func test_score_accumulation() -> void:
	var player = PlayerScript.new("Alice", 1)
	player.add_score(5)
	assert_int(player.score).is_equal(5)
	player.add_score(-3)
	assert_int(player.score).is_equal(2)


func test_reset_score() -> void:
	var player = PlayerScript.new("Alice", 1)
	player.add_score(10)
	player.reset_score()
	assert_int(player.score).is_equal(0)

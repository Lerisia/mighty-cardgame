extends Node

const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")

const SAVE_PATH := "user://options.cfg"

var options: GameOptionsScript

const FIELDS := [
	["bidding", "min_bid", "int"],
	["bidding", "allow_giruda_change_before_kitty", "bool"],
	["bidding", "allow_giruda_change_after_kitty", "bool"],
	["bidding", "bid_20_run_double", "bool"],

	["friend", "allow_player_friend", "bool"],
	["friend", "allow_fake_friend", "bool"],
	["friend", "allow_last_trick_friend", "bool"],

	["special_cards", "alter_mighty_suit", "int"],
	["special_cards", "alter_mighty_rank", "int"],
	["special_cards", "alter_joker_call_suit", "int"],
	["special_cards", "alter_joker_call_rank", "int"],
	["special_cards", "first_trick_mighty_effect", "bool"],
	["special_cards", "last_trick_mighty_effect", "bool"],
	["special_cards", "first_trick_joker_effect", "bool"],
	["special_cards", "last_trick_joker_effect", "bool"],
	["special_cards", "joker_called_joker_effect", "bool"],

	["scoring", "back_run_method", "int"],

	["deal_miss", "deal_miss_penalty_method", "int"],
	["deal_miss", "deal_miss_fixed_penalty", "int"],
	["deal_miss", "deal_miss_doubling_base", "int"],
	["deal_miss", "deal_miss_dealer_to_declarer", "bool"],
	["deal_miss", "deal_miss_threshold", "float"],
	["deal_miss", "deal_miss_threshold_type", "int"],
	["deal_miss", "deal_miss_joker_score", "float"],
	["deal_miss", "deal_miss_mighty_score", "float"],
	["deal_miss", "deal_miss_ten_score", "float"],
	["deal_miss", "deal_miss_point_card_score", "float"],
	["deal_miss", "deal_miss_non_point_score", "float"],

	["display", "suit_display_style", "int"],
]


func _ready() -> void:
	options = GameOptionsScript.new()
	load_options()


func save_options() -> void:
	var cfg := ConfigFile.new()
	for field in FIELDS:
		cfg.set_value(field[0], field[1], options.get(field[1]))
	cfg.save(SAVE_PATH)


func load_options() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var defaults := GameOptionsScript.new()
	for field in FIELDS:
		var val = cfg.get_value(field[0], field[1], defaults.get(field[1]))
		options.set(field[1], val)


func reset_to_defaults() -> void:
	options = GameOptionsScript.new()
	save_options()

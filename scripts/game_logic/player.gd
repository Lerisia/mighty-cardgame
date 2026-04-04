class_name Player
extends RefCounted

var player_name: String
var id: int
var is_bot: bool
var score: int = 0


func _init(p_name: String, p_id: int, p_is_bot: bool = false) -> void:
	player_name = p_name
	id = p_id
	is_bot = p_is_bot


func add_score(amount: int) -> void:
	score += amount


func reset_score() -> void:
	score = 0

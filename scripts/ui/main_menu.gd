extends Control


func _ready() -> void:
	$VBox/PlayVsBot.pressed.connect(_on_play_vs_bot)
	$VBox/Options.pressed.connect(_on_options)
	$VBox/Quit.pressed.connect(_on_quit)


func _on_play_vs_bot() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game_screen.tscn")


func _on_options() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/options_screen.tscn")


func _on_quit() -> void:
	get_tree().quit()

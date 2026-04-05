extends Control


func _ready() -> void:
	$VBox/ButtonRow1/PlayVsBot.pressed.connect(_on_play_vs_bot)
	get_viewport().size_changed.connect(_update_font_sizes)
	_update_font_sizes()


func _on_play_vs_bot() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game_screen.tscn")


func _update_font_sizes() -> void:
	var vh: float = get_viewport_rect().size.y
	var title_size: int = int(vh / 10.0)
	var button_size: int = int(vh / 25.0)

	$VBox/Title.add_theme_font_size_override("font_size", title_size)

	for row in [$VBox/ButtonRow1, $VBox/ButtonRow2]:
		for btn in row.get_children():
			if btn is Button:
				btn.add_theme_font_size_override("font_size", button_size)

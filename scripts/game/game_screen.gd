extends Control

const CardUtilScript = preload("res://scripts/ui/card_util.gd")
const CardTextureScript = preload("res://scripts/ui/card_texture.gd")


func _ready() -> void:
	_play_shuffle_animation()


func _play_shuffle_animation() -> void:
	var center: Vector2 = CardUtilScript.get_center(get_viewport())
	var card_size: Vector2 = CardUtilScript.get_card_size(get_viewport())
	var back_tex: Texture2D = CardTextureScript.get_back_texture()
	var half_w: float = card_size.x / 2.0
	var half_h: float = card_size.y / 2.0
	var card_origin: Vector2 = center - Vector2(half_w, half_h)

	var left_pos: Vector2 = card_origin + Vector2(-half_w - 5, 0)
	var right_pos: Vector2 = card_origin + Vector2(half_w + 5, 0)

	var num_cards: int = 10
	var cards: Array = []

	for i in range(num_cards):
		var tex := TextureRect.new()
		tex.texture = back_tex
		tex.custom_minimum_size = card_size
		tex.size = card_size
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex.position = card_origin
		add_child(tex)
		cards.append(tex)

	var tween: Tween = create_tween()

	for i in range(num_cards):
		var card = cards[i]
		var target: Vector2 = left_pos if i % 2 == 0 else right_pos
		tween.tween_property(card, "position", target, 0.08)

	tween.tween_interval(0.15)

	for i in range(num_cards):
		var idx: int = num_cards - 1 - i
		var card = cards[idx]
		var drop_offset: Vector2 = Vector2(0, -i * 2)
		tween.tween_property(card, "position", card_origin + drop_offset, 0.06)

	tween.tween_interval(0.3)

	tween.tween_callback(func():
		for card in cards:
			card.queue_free()
	)

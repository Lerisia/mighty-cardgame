extends Control

const CardUtilScript = preload("res://scripts/ui/card_util.gd")
const CardTextureScript = preload("res://scripts/ui/card_texture.gd")


func _ready() -> void:
	_play_shuffle_animation()


func _create_card_back(card_size: Vector2) -> TextureRect:
	var tex := TextureRect.new()
	tex.texture = CardTextureScript.get_back_texture()
	tex.size = card_size
	tex.stretch_mode = TextureRect.STRETCH_SCALE
	return tex


func _play_shuffle_animation() -> void:
	var center: Vector2 = CardUtilScript.get_center(get_viewport())
	var card_size: Vector2 = CardUtilScript.get_card_size(get_viewport())
	var half_card: Vector2 = card_size / 2.0
	var card_origin: Vector2 = center - half_card

	var left_pos: Vector2 = card_origin + Vector2(-half_card.x - 5, 0)
	var right_pos: Vector2 = card_origin + Vector2(half_card.x + 5, 0)

	var num_cards: int = 10
	var cards: Array = []

	for i in range(num_cards):
		var card: TextureRect = _create_card_back(card_size)
		card.position = card_origin
		add_child(card)
		cards.append(card)

	var tween: Tween = create_tween()

	for i in range(num_cards):
		var card: TextureRect = cards[i]
		var target: Vector2 = left_pos if i % 2 == 0 else right_pos
		tween.tween_property(card, "position", target, 0.08)

	tween.tween_interval(0.15)

	for i in range(num_cards):
		var idx: int = num_cards - 1 - i
		var card: TextureRect = cards[idx]
		var drop_offset: Vector2 = Vector2(0, -i * 2)
		tween.tween_property(card, "position", card_origin + drop_offset, 0.06)

	tween.tween_interval(0.3)

	tween.tween_callback(func():
		for card in cards:
			card.queue_free()
	)

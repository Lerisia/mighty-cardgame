extends Control

const CardUtilScript = preload("res://scripts/ui/card_util.gd")
const CardTextureScript = preload("res://scripts/ui/card_texture.gd")

const CARD_BORDER := 2.0
const CARD_BORDER_COLOR := Color(0.15, 0.15, 0.15, 1.0)

var placed_cards: Array = []


func _ready() -> void:
	_play_shuffle_animation()


func _create_card_back(card_size: Vector2) -> Control:
	var container := Control.new()
	var border := ColorRect.new()
	border.color = CARD_BORDER_COLOR
	border.position = Vector2(-CARD_BORDER, -CARD_BORDER)
	border.size = card_size + Vector2(CARD_BORDER * 2, CARD_BORDER * 2)
	container.add_child(border)
	var tex := TextureRect.new()
	tex.texture = CardTextureScript.get_back_texture()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	container.add_child(tex)
	return container


func _add_card(card: Control, card_size: Vector2, pos: Vector2) -> void:
	add_child(card)
	card.get_child(1).size = card_size
	card.size = card_size
	card.position = pos
	placed_cards.append(card)


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
		var card: Control = _create_card_back(card_size)
		_add_card(card, card_size, card_origin)
		cards.append(card)

	var tween: Tween = create_tween()

	for i in range(num_cards):
		var card: Control = cards[i]
		var target: Vector2 = left_pos if i % 2 == 0 else right_pos
		tween.tween_property(card, "position", target, 0.08)

	tween.tween_interval(0.15)

	for i in range(num_cards):
		var idx: int = num_cards - 1 - i
		var card: Control = cards[idx]
		var drop_offset: Vector2 = Vector2(0, -i * 2)
		tween.tween_property(card, "position", card_origin + drop_offset, 0.06)

	tween.tween_interval(0.3)

	tween.tween_callback(func():
		for card in cards:
			card.queue_free()
		_place_all_hands()
	)


func _place_all_hands() -> void:
	var card_size: Vector2 = CardUtilScript.get_card_size(get_viewport())

	for p in range(5):
		for i in range(10):
			var card: Control = _create_card_back(card_size)
			var pos: Vector2 = CardUtilScript.get_card_position(get_viewport(), p, i, 10)
			_add_card(card, card_size, pos)

extends Control

const CardUtilScript = preload("res://scripts/ui/card_util.gd")
const CardTextureScript = preload("res://scripts/ui/card_texture.gd")

const CARD_BORDER := 2.0
const CARD_BORDER_COLOR := Color(0.15, 0.15, 0.15, 1.0)
const DEAL_FLY_DURATION := 0.15
const DEAL_PATTERN := [1, 2, 3, 4]

var placed_cards: Array = []
var player_card_counts: Array = [0, 0, 0, 0, 0]
var dealer_index: int = 0


func _ready() -> void:
	dealer_index = randi() % 5
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
		_play_deal_animation()
	)


func _play_deal_animation() -> void:
	var center: Vector2 = CardUtilScript.get_center(get_viewport())
	var card_size: Vector2 = CardUtilScript.get_card_size(get_viewport())
	var half_card: Vector2 = card_size / 2.0
	var deck_pos: Vector2 = center - half_card

	var deck_card: Control = _create_card_back(card_size)
	_add_card(deck_card, card_size, deck_pos)

	var tween: Tween = create_tween()
	var current_player: int = dealer_index
	var deal_round_index: int = 0

	for round_num in range(4):
		for p in range(5):
			var target_player: int = (current_player + p) % 5
			var num_to_deal: int = DEAL_PATTERN[(deal_round_index + p) % 4]

			for c in range(num_to_deal):
				var card_idx: int = player_card_counts[target_player]
				var target_pos: Vector2 = CardUtilScript.get_card_position(get_viewport(), target_player, card_idx, 10)

				tween.tween_callback(func():
					var card: Control = _create_card_back(card_size)
					_add_card(card, card_size, deck_pos)
					var tw: Tween = create_tween()
					tw.tween_property(card, "position", target_pos, DEAL_FLY_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
				)
				player_card_counts[target_player] += 1

			tween.tween_interval(DEAL_FLY_DURATION + 0.05)

		deal_round_index += 1

	tween.tween_callback(func():
		deck_card.queue_free()
	)

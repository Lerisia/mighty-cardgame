extends Control

const CardUtilScript = preload("res://scripts/ui/card_util.gd")
const CardTextureScript = preload("res://scripts/ui/card_texture.gd")
const DeckScript = preload("res://scripts/game_logic/deck.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")

const CARD_BORDER := 1.0
const CARD_BORDER_COLOR := Color(0.15, 0.15, 0.15, 1.0)
const DEAL_FLY_DURATION := 0.22
const DEAL_PATTERN := [1, 2, 3, 4]

var placed_cards: Array = []
var p0_card_nodes: Array = []
var name_labels: Array = []
var score_labels: Array = []
var player_card_counts: Array = [0, 0, 0, 0, 0]
var dealer_index: int = 0
var hands: Array = []
var kitty: Array = []

const PLAYER_NAMES := ["나", "준규", "지훈", "한별", "민욱"]


func _ready() -> void:
	dealer_index = randi() % 5
	var deck = DeckScript.new()
	var result: Dictionary = deck.deal(5)
	hands = result["hands"]
	kitty = result["kitty"]
	$TopButtons/ExitButton.pressed.connect(_on_exit_pressed)
	$ExitConfirmPopup/VBox/Buttons/ConfirmExit.pressed.connect(_on_confirm_exit)
	$ExitConfirmPopup/VBox/Buttons/CancelExit.pressed.connect(_on_cancel_exit)
	_style_top_buttons()
	_play_shuffle_animation()


func _style_top_buttons() -> void:
	var vh: float = get_viewport_rect().size.y
	var btn_font_size: int = int(vh / 30.0)

	var exit_style := StyleBoxFlat.new()
	exit_style.bg_color = Color(0.7, 0.15, 0.15)
	exit_style.set_corner_radius_all(6)
	exit_style.set_content_margin_all(8)
	$TopButtons/ExitButton.add_theme_stylebox_override("normal", exit_style)
	var exit_hover := StyleBoxFlat.new()
	exit_hover.bg_color = Color(0.85, 0.2, 0.2)
	exit_hover.set_corner_radius_all(6)
	exit_hover.set_content_margin_all(8)
	$TopButtons/ExitButton.add_theme_stylebox_override("hover", exit_hover)
	$TopButtons/ExitButton.add_theme_font_size_override("font_size", btn_font_size)
	$TopButtons/ExitButton.add_theme_color_override("font_color", Color.WHITE)

	var stats_style := StyleBoxFlat.new()
	stats_style.bg_color = Color(0.15, 0.2, 0.5)
	stats_style.set_corner_radius_all(6)
	stats_style.set_content_margin_all(8)
	$TopButtons/StatsButton.add_theme_stylebox_override("normal", stats_style)
	var stats_disabled := StyleBoxFlat.new()
	stats_disabled.bg_color = Color(0.2, 0.25, 0.4, 0.6)
	stats_disabled.set_corner_radius_all(6)
	stats_disabled.set_content_margin_all(8)
	$TopButtons/StatsButton.add_theme_stylebox_override("disabled", stats_disabled)
	$TopButtons/StatsButton.add_theme_font_size_override("font_size", btn_font_size)
	$TopButtons/StatsButton.add_theme_color_override("font_color", Color.WHITE)


func _on_exit_pressed() -> void:
	$ExitConfirmPopup.popup_centered()


func _on_confirm_exit() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_cancel_exit() -> void:
	$ExitConfirmPopup.hide()


const CARD_CORNER_RADIUS := 4.0


func _create_border(card_size: Vector2) -> Panel:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BORDER_COLOR
	style.set_corner_radius_all(int(CARD_CORNER_RADIUS + CARD_BORDER))
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(-CARD_BORDER, -CARD_BORDER)
	panel.size = card_size + Vector2(CARD_BORDER * 2, CARD_BORDER * 2)
	return panel


func _create_card_back(card_size: Vector2) -> Control:
	var container := Control.new()
	container.add_child(_create_border(card_size))
	var tex := TextureRect.new()
	tex.texture = CardTextureScript.get_back_texture()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	container.add_child(tex)
	return container


func _create_card_front(card_size: Vector2, card) -> Control:
	var container := Control.new()
	container.add_child(_create_border(card_size))
	var tex := TextureRect.new()
	tex.texture = CardTextureScript.get_texture(card)
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
	var my_card_size: Vector2 = CardUtilScript.get_my_card_size(get_viewport())
	var half_card: Vector2 = card_size / 2.0
	var deck_pos: Vector2 = center - half_card

	var kitty_cards: Array = []
	for k in range(3):
		var kitty_card: Control = _create_card_back(card_size)
		var kitty_offset: Vector2 = Vector2(k * 3, k * 2)
		_add_card(kitty_card, card_size, deck_pos + kitty_offset)
		kitty_cards.append(kitty_card)

	var deck_card: Control = _create_card_back(card_size)
	_add_card(deck_card, card_size, deck_pos)

	var tween: Tween = create_tween()
	var current_player: int = dealer_index
	var deal_round_index: int = 0
	var p0_deal_index: int = 0

	for round_num in range(4):
		for p in range(5):
			var target_player: int = (current_player + p) % 5
			var num_to_deal: int = DEAL_PATTERN[(deal_round_index + p) % 4]

			for c in range(num_to_deal):
				var card_idx: int = player_card_counts[target_player]
				var target_pos: Vector2 = CardUtilScript.get_card_position(get_viewport(), target_player, card_idx, 10)
				var is_p0: bool = target_player == 0
				var p0_idx: int = p0_deal_index

				tween.tween_callback(func():
					var card: Control
					var sz: Vector2
					if is_p0:
						sz = my_card_size
						card = _create_card_front(sz, hands[0][p0_idx])
						p0_card_nodes.append({"node": card, "card_data": hands[0][p0_idx]})
					else:
						sz = card_size
						card = _create_card_back(sz)
					_add_card(card, sz, deck_pos)
					var tw: Tween = create_tween()
					tw.tween_property(card, "position", target_pos, DEAL_FLY_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
				)
				player_card_counts[target_player] += 1
				if is_p0:
					p0_deal_index += 1

			tween.tween_interval(DEAL_FLY_DURATION + 0.07)

		deal_round_index += 1

	tween.tween_callback(func():
		deck_card.queue_free()
	)
	tween.tween_interval(0.3)
	tween.tween_callback(_sort_and_rearrange_p0)


func _sort_hand(hand: Array) -> Array:
	const SUIT_ORDER := {
		CardScript.Suit.SPADE: 0,
		CardScript.Suit.DIAMOND: 1,
		CardScript.Suit.HEART: 2,
		CardScript.Suit.CLUB: 3,
	}
	var sorted: Array = hand.duplicate()
	sorted.sort_custom(func(a, b):
		if a.is_joker:
			return true
		if b.is_joker:
			return false
		if SUIT_ORDER[a.suit] != SUIT_ORDER[b.suit]:
			return SUIT_ORDER[a.suit] < SUIT_ORDER[b.suit]
		return a.rank > b.rank
	)
	return sorted


func _sort_and_rearrange_p0() -> void:
	var sorted_hand: Array = _sort_hand(hands[0])
	var card_size: Vector2 = CardUtilScript.get_card_size(get_viewport())
	var total: int = sorted_hand.size()

	var sorted_nodes: Array = []
	for sorted_card in sorted_hand:
		for entry in p0_card_nodes:
			if not entry.has("used") and _cards_equal(entry["card_data"], sorted_card):
				sorted_nodes.append(entry["node"])
				entry["used"] = true
				break

	var tween: Tween = create_tween().set_parallel(true)
	for i in range(sorted_nodes.size()):
		var target_pos: Vector2 = CardUtilScript.get_card_position(get_viewport(), 0, i, total)
		var node: Control = sorted_nodes[i]
		if is_instance_valid(node):
			node.z_index = i
			tween.tween_property(node, "position", target_pos, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

	hands[0] = sorted_hand

	for entry in p0_card_nodes:
		if entry.has("used"):
			entry.erase("used")

	tween.set_parallel(false)
	tween.tween_interval(0.3)
	tween.tween_callback(_show_player_names)


var _bold_font: Font = null


func _get_bold_font() -> Font:
	if _bold_font == null:
		_bold_font = load("res://assets/fonts/NanumSquareRoundB.ttf")
	return _bold_font


func _create_label(text: String, font_size: int, color: Color = Color.WHITE, bold: bool = true) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_font_override("font", _get_bold_font())
	return label


func _show_player_names() -> void:
	for label in name_labels:
		if is_instance_valid(label):
			label.queue_free()
	name_labels.clear()
	for label in score_labels:
		if is_instance_valid(label):
			label.queue_free()
	score_labels.clear()

	var vp: Vector2 = get_viewport_rect().size
	var cs: Vector2 = CardUtilScript.get_card_size(get_viewport())
	var my_cs: Vector2 = CardUtilScript.get_my_card_size(get_viewport())
	var font_size: int = int(vp.y / 22.0)

	for p in range(5):
		var origin: Vector2 = CardUtilScript.get_hand_origin(get_viewport(), p)
		var name_label: Label = _create_label(PLAYER_NAMES[p], font_size)
		var score_label: Label = _create_label("1000점", font_size, Color(1.0, 0.9, 0.5))

		add_child(name_label)
		add_child(score_label)

		var name_pos: Vector2
		var score_pos: Vector2
		var line_h: float = font_size + 6

		match p:
			0:
				var hand_right: float = origin.x + CardUtilScript._my_hand_width(my_cs, 10)
				name_pos = Vector2(hand_right + 15, origin.y)
				score_pos = Vector2(hand_right + 15, origin.y + line_h)
			1:
				var card_right: float = origin.x + cs.x
				var card_mid_bottom: float = origin.y + cs.y * CardUtilScript.CARD_OVERLAP_V * 9 * 0.5 + cs.y * 0.5
				name_pos = Vector2(card_right + 8, card_mid_bottom + 5)
				score_pos = Vector2(card_right + 8, card_mid_bottom + 5 + line_h)
			2:
				var card_bottom: float = cs.y * 0.5
				name_pos = Vector2(origin.x, card_bottom + 8)
				score_pos = Vector2(origin.x + font_size * 3, card_bottom + 8)
			3:
				var hand_w: float = CardUtilScript._hand_width(cs, 10)
				var card_bottom: float = cs.y * 0.5
				var right_x: float = origin.x + hand_w
				name_pos = Vector2(right_x - font_size * 6, card_bottom + 8)
				score_pos = Vector2(right_x - font_size * 3, card_bottom + 8)
			4:
				var card_left: float = origin.x
				var card_mid_bottom: float = origin.y + cs.y * CardUtilScript.CARD_OVERLAP_V * 9 * 0.5 + cs.y * 0.5
				name_pos = Vector2(card_left - font_size * 3 - 8, card_mid_bottom + 5)
				score_pos = Vector2(card_left - font_size * 3 - 8, card_mid_bottom + 5 + line_h)

		name_label.position = name_pos
		score_label.position = score_pos
		name_labels.append(name_label)
		score_labels.append(score_label)


func _cards_equal(a, b) -> bool:
	if a.is_joker and b.is_joker:
		return true
	if a.is_joker or b.is_joker:
		return false
	return a.suit == b.suit and a.rank == b.rank

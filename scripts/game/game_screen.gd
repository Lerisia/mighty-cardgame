extends Control

const CardUtilScript = preload("res://scripts/ui/card_util.gd")
const CardTextureScript = preload("res://scripts/ui/card_texture.gd")
const DeckScript = preload("res://scripts/game_logic/deck.gd")
const CardScript = preload("res://scripts/game_logic/card.gd")

const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const BiddingManagerScript = preload("res://scripts/game_logic/bidding_manager.gd")
const BotManagerScript = preload("res://scripts/ai/bot_manager.gd")
const BSWStrategyScript = preload("res://scripts/ai/bsw_strategy.gd")
const XiaoStrategyScript = preload("res://scripts/ai/xiao_strategy.gd")
const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")

const CARD_BORDER := 1.0
const CARD_BORDER_COLOR := Color(0.15, 0.15, 0.15, 1.0)
const DEAL_FLY_DURATION := 0.22
const DEAL_PATTERN := [1, 2, 3, 4]

const SUIT_DISPLAY := {
	BiddingStateScript.Giruda.SPADE: "스페이드",
	BiddingStateScript.Giruda.DIAMOND: "다이아",
	BiddingStateScript.Giruda.HEART: "하트",
	BiddingStateScript.Giruda.CLUB: "클로버",
	BiddingStateScript.Giruda.NO_GIRUDA: "노기루",
}

const MIN_BID := 13
const MAX_BID := 20

var placed_cards: Array = []
var p0_card_nodes: Array = []
var crown_nodes: Array = []
var kitty_card_nodes: Array = []
var bot_hand_nodes: Dictionary = {1: [], 2: [], 3: [], 4: []}
var name_labels: Array = []
var score_labels: Array = []
var player_card_counts: Array = [0, 0, 0, 0, 0]
var dealer_index: int = 0
var hands: Array = []
var kitty: Array = []

const PLAYER_NAMES := ["나", "준규", "지훈", "한별", "민욱"]

var selected_suit: int = BiddingStateScript.Giruda.SPADE
var selected_bid: int = MIN_BID
var election_round: int = 1

var bidding_manager = null
var bots: Array = []
var bid_labels: Array = [null, null, null, null, null]
var bidding_active: bool = false


func _ready() -> void:
	dealer_index = randi() % 5
	var deck = DeckScript.new()
	var result: Dictionary = deck.deal(5)
	hands = result["hands"]
	kitty = result["kitty"]
	for i in range(1, 5):
		if i % 2 == 0:
			bots.append(BotManagerScript.new(BSWStrategyScript.new(), i))
		else:
			bots.append(BotManagerScript.new(XiaoStrategyScript.new(), i))
	$TopButtons/ExitButton.pressed.connect(_on_exit_pressed)
	$ExitConfirmPopup/VBox/Buttons/ConfirmExit.pressed.connect(_on_confirm_exit)
	$ExitConfirmPopup/VBox/Buttons/CancelExit.pressed.connect(_on_cancel_exit)
	_setup_bid_panel()
	_style_top_buttons()
	_play_shuffle_animation()


func _style_top_buttons() -> void:
	var vh: float = get_viewport_rect().size.y
	var btn_font_size: int = int(vh / 24.0)

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


func _setup_bid_panel() -> void:
	var suits = $BidPanel/VBox/TopRow/SuitGrid
	suits.get_node("Spade").pressed.connect(func(): _select_suit(BiddingStateScript.Giruda.SPADE))
	suits.get_node("Diamond").pressed.connect(func(): _select_suit(BiddingStateScript.Giruda.DIAMOND))
	suits.get_node("Heart").pressed.connect(func(): _select_suit(BiddingStateScript.Giruda.HEART))
	suits.get_node("Club").pressed.connect(func(): _select_suit(BiddingStateScript.Giruda.CLUB))
	suits.get_node("NoGiruda").pressed.connect(func(): _select_suit(BiddingStateScript.Giruda.NO_GIRUDA))
	$BidPanel/VBox/TopRow/ArrowBox/UpButton.pressed.connect(_on_bid_up)
	$BidPanel/VBox/TopRow/ArrowBox/DownButton.pressed.connect(_on_bid_down)
	$BidPanel/VBox/BottomRow/BidButton.pressed.connect(_on_bid_submit)
	$BidPanel/VBox/BottomRow/PassButton.pressed.connect(_on_bid_pass)




func _style_bid_panel() -> void:
	var vh: float = get_viewport_rect().size.y
	var big_font: int = int(vh / 12.0)
	var btn_font: int = int(vh / 20.0)
	var label_font: int = int(vh / 18.0)
	var icon_size: int = int(vh / 8.0)

	var grid = $BidPanel/VBox/TopRow/SuitGrid
	for suit_name in ["Spade", "Diamond", "Heart", "Club", "NoGiruda"]:
		var btn = grid.get_node(suit_name)
		btn.custom_minimum_size = Vector2(icon_size, icon_size)

	$BidPanel/VBox/TopRow/BidDisplay.add_theme_font_size_override("font_size", big_font)
	$BidPanel/VBox/TopRow/BidDisplay.add_theme_font_override("font", _get_bold_font())
	$BidPanel/VBox/TopRow/BidDisplay.custom_minimum_size.x = big_font * 6
	$ElectionPanel/ElectionLabel.add_theme_font_size_override("font_size", label_font)
	$ElectionPanel/ElectionLabel.add_theme_font_override("font", _get_bold_font())
	$ElectionPanel/ElectionLabel.add_theme_color_override("font_color", Color.WHITE)
	for btn_name in ["BidButton", "PassButton", "DealMissButton"]:
		var btn: Button = $BidPanel/VBox/BottomRow.get_node(btn_name)
		btn.add_theme_font_size_override("font_size", btn_font)
		btn.add_theme_font_override("font", _get_bold_font())
	$BidPanel/VBox/TopRow/ArrowBox/UpButton.add_theme_font_size_override("font_size", btn_font)
	$BidPanel/VBox/TopRow/ArrowBox/DownButton.add_theme_font_size_override("font_size", btn_font)
	_update_suit_highlight()


func _update_bid_display() -> void:
	var suit_str: String = SUIT_DISPLAY[selected_suit]
	$BidPanel/VBox/TopRow/BidDisplay.text = "%s %d" % [suit_str, selected_bid]
	_update_suit_highlight()

	if bidding_manager and bidding_manager.highest_bidder >= 0:
		var hb: int = bidding_manager.highest_bidder
		var hg: int = bidding_manager.highest_giruda
		$ElectionPanel/ElectionLabel.text = "제 %d회 선거\n최고: %s - %s %d" % [election_round, PLAYER_NAMES[hb], SUIT_DISPLAY.get(hg, "?"), bidding_manager.highest_bid]
	else:
		$ElectionPanel/ElectionLabel.text = "제 %d회 선거" % election_round


func _ensure_gold_borders() -> void:
	var suit_names := ["Spade", "Diamond", "Heart", "Club", "NoGiruda"]
	var grid = $BidPanel/VBox/TopRow/SuitGrid
	for suit_name in suit_names:
		var btn = grid.get_node_or_null(suit_name)
		if btn == null:
			continue
		if btn.get_node_or_null("GoldBorder") != null:
			continue
		var border := Panel.new()
		border.name = "GoldBorder"
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.border_color = Color(1.0, 0.8, 0.2)
		style.set_border_width_all(3)
		style.set_corner_radius_all(4)
		border.add_theme_stylebox_override("panel", style)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		border.visible = false
		btn.add_child(border)


func _update_suit_highlight() -> void:
	_ensure_gold_borders()
	var suit_map := {
		BiddingStateScript.Giruda.SPADE: "Spade",
		BiddingStateScript.Giruda.DIAMOND: "Diamond",
		BiddingStateScript.Giruda.HEART: "Heart",
		BiddingStateScript.Giruda.CLUB: "Club",
		BiddingStateScript.Giruda.NO_GIRUDA: "NoGiruda",
	}
	var grid = $BidPanel/VBox/TopRow/SuitGrid
	for suit_val in suit_map:
		var node_name: String = suit_map[suit_val]
		var btn = grid.get_node_or_null(node_name)
		if btn == null:
			continue
		var border = btn.get_node_or_null("GoldBorder")
		if border:
			border.visible = (suit_val == selected_suit)


func _select_suit(suit: int) -> void:
	selected_suit = suit
	_update_bid_display()


func _on_bid_up() -> void:
	if selected_bid < MAX_BID:
		selected_bid += 1
		_update_bid_display()


func _on_bid_down() -> void:
	var min_allowed: int = MIN_BID
	if bidding_manager and bidding_manager.highest_bid >= MIN_BID:
		min_allowed = bidding_manager.highest_bid + 1
	if selected_bid > min_allowed:
		selected_bid -= 1
		_update_bid_display()


func _on_bid_submit() -> void:
	$BidPanel.visible = false
	if bidding_manager.place_bid(0, selected_bid, selected_suit):
		_show_player_bid(0, selected_suit, selected_bid)
		_play_sfx(_sfx_bid)
	else:
		_show_player_bid_text(0, "무효")
	_update_bid_display()
	_continue_bidding()


func _on_bid_pass() -> void:
	$BidPanel.visible = false
	bidding_manager.pass_turn(0)
	_show_player_bid_text(0, "패스")
	_play_sfx(_sfx_pass)
	_update_bid_display()
	_continue_bidding()


func _start_bidding() -> void:
	var bidding_hands: Array = []
	for h in hands:
		bidding_hands.append(h.duplicate())
	bidding_manager = BiddingManagerScript.new(5, dealer_index, bidding_hands, MIN_BID)
	bidding_active = true
	$ElectionPanel/ElectionLabel.text = "제 %d회 선거" % election_round
	$ElectionPanel.visible = true
	$ElectionPanel.z_index = 100
	var el_style := StyleBoxFlat.new()
	el_style.bg_color = Color(0, 0, 0, 0.6)
	el_style.set_corner_radius_all(6)
	el_style.set_content_margin_all(8)
	$ElectionPanel.add_theme_stylebox_override("panel", el_style)
	_style_election_label()
	_continue_bidding()


func _style_election_label() -> void:
	var vh: float = get_viewport_rect().size.y
	var label_font: int = int(vh / 18.0)
	$ElectionPanel/ElectionLabel.add_theme_font_size_override("font_size", label_font)
	$ElectionPanel/ElectionLabel.add_theme_font_override("font", _get_bold_font())
	$ElectionPanel/ElectionLabel.add_theme_color_override("font_color", Color.WHITE)


func _continue_bidding() -> void:
	if _check_all_passed():
		await get_tree().create_timer(1.5).timeout
		await _handle_deal_miss()
		return

	if bidding_manager.is_finished():
		await get_tree().create_timer(1.5).timeout
		_end_bidding_with_declarer()
		return

	var turn: int = bidding_manager.current_turn

	if turn == 0:
		await get_tree().create_timer(1.0).timeout
		_show_bid_panel_for_player()
	else:
		await get_tree().create_timer(1.5).timeout
		_do_bot_bid(turn)


func _check_all_passed() -> bool:
	for i in range(5):
		if not bidding_manager.states[i].passed:
			return false
	return bidding_manager.highest_bidder < 0


func _handle_deal_miss() -> void:
	_end_bidding()
	await _show_announcement_stay("전원 패스!\n카드를 다시 섞습니다...")
	await get_tree().create_timer(2.0).timeout
	_hide_announcement()

	for card in placed_cards:
		if is_instance_valid(card):
			card.queue_free()
	placed_cards.clear()
	p0_card_nodes.clear()
	kitty_card_nodes.clear()
	bot_hand_nodes = {1: [], 2: [], 3: [], 4: []}
	for label in name_labels:
		if is_instance_valid(label):
			label.queue_free()
	name_labels.clear()
	for label in score_labels:
		if is_instance_valid(label):
			label.queue_free()
	score_labels.clear()
	for c in crown_nodes:
		if is_instance_valid(c):
			c.queue_free()
	crown_nodes.clear()

	player_card_counts = [0, 0, 0, 0, 0]
	var deck = DeckScript.new()
	var result: Dictionary = deck.deal(5)
	hands = result["hands"]
	kitty = result["kitty"]
	election_round += 1

	_play_shuffle_animation()


func _show_bid_panel_for_player() -> void:
	if bidding_manager.highest_bid >= MIN_BID:
		selected_bid = bidding_manager.highest_bid + 1
		if selected_bid > MAX_BID:
			selected_bid = MAX_BID
	else:
		selected_bid = MIN_BID
	selected_suit = BiddingStateScript.Giruda.SPADE
	_update_bid_display()

	$BidPanel.visible = true
	$BidPanel.z_index = 100
	_style_bid_panel()


func _do_bot_bid(bot_player: int) -> void:
	var bot_idx: int = bot_player - 1
	if bot_idx < 0 or bot_idx >= bots.size():
		_continue_bidding()
		return

	var before_bid: int = bidding_manager.highest_bid
	bots[bot_idx].do_bidding_turn(bidding_manager, kitty)
	var after_bid: int = bidding_manager.highest_bid

	if bidding_manager.states[bot_player].passed:
		_show_player_bid_text(bot_player, "패스")
		_play_sfx(_sfx_pass)
	elif after_bid > before_bid:
		var g: int = bidding_manager.states[bot_player].bid_giruda
		_show_player_bid(bot_player, g, after_bid)
		_play_sfx(_sfx_bid)

	_update_bid_display()
	_continue_bidding()


func _show_player_bid(player_index: int, giruda: int, bid: int) -> void:
	var text: String = "%s %d" % [SUIT_DISPLAY.get(giruda, "?"), bid]
	_show_player_bid_text(player_index, text)


func _show_player_bid_text(player_index: int, text: String) -> void:
	if bid_labels[player_index] != null and is_instance_valid(bid_labels[player_index]):
		bid_labels[player_index].queue_free()

	var vh: float = get_viewport_rect().size.y
	var font_size: int = int(vh / 25.0)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	panel.z_index = 90

	var label: Label = _create_label(text, font_size, Color.YELLOW)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)

	var origin: Vector2 = CardUtilScript.get_hand_origin(get_viewport(), player_index)
	var cs: Vector2 = CardUtilScript.get_card_size(get_viewport())

	var vert_cards_h: float = cs.y + cs.y * CardUtilScript.CARD_OVERLAP_V * 9
	match player_index:
		0:
			var my_cs: Vector2 = CardUtilScript.get_my_card_size(get_viewport())
			panel.position = Vector2(origin.x + CardUtilScript._my_hand_width(my_cs, 10) / 2.0, origin.y - font_size - 20)
		1:
			panel.position = Vector2(origin.x + cs.x + 10, origin.y + vert_cards_h * 0.6)
		2:
			panel.position = Vector2(origin.x, cs.y * 0.5 + 30)
		3:
			var hand_w: float = CardUtilScript._hand_width(cs, 10)
			panel.position = Vector2(origin.x + hand_w / 2.0, cs.y * 0.5 + 30)
		4:
			panel.position = Vector2(origin.x - font_size * 5, origin.y + vert_cards_h * 0.6)

	add_child(panel)
	bid_labels[player_index] = panel


func _clear_bid_labels() -> void:
	for i in range(5):
		if bid_labels[i] != null and is_instance_valid(bid_labels[i]):
			bid_labels[i].queue_free()
			bid_labels[i] = null


func _end_bidding() -> void:
	bidding_active = false
	$ElectionPanel.visible = false
	$BidPanel.visible = false
	_clear_bid_labels()


func _end_bidding_with_declarer() -> void:
	_end_bidding()
	_start_declarer_phase()


var _announcement_panel: PanelContainer = null


func _show_announcement_stay(text: String) -> void:
	_hide_announcement()
	var vh: float = get_viewport_rect().size.y
	var font_size: int = int(vh / 18.0)

	_announcement_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	_announcement_panel.add_theme_stylebox_override("panel", style)
	_announcement_panel.z_index = 110

	var label: Label = _create_label(text, font_size, Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announcement_panel.add_child(label)

	add_child(_announcement_panel)
	await get_tree().process_frame
	_announcement_panel.position = get_viewport_rect().size / 2.0 - _announcement_panel.size / 2.0


func _show_crown(declarer: int) -> void:
	for c in crown_nodes:
		if is_instance_valid(c):
			c.queue_free()
	crown_nodes.clear()

	if declarer < 0 or declarer >= name_labels.size():
		return
	var name_label: Label = name_labels[declarer]
	if not is_instance_valid(name_label):
		return

	var vh: float = get_viewport_rect().size.y
	var icon_size: int = int(vh / 25.0)
	var crown_tex: Texture2D = load("res://assets/icons/crown.png")

	var crown := TextureRect.new()
	crown.texture = crown_tex
	crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown.z_index = 95
	add_child(crown)
	crown.size = Vector2(icon_size, icon_size)

	var name_pos: Vector2 = name_label.position
	match declarer:
		0:
			crown.position = Vector2(name_pos.x + name_label.size.x + 5, name_pos.y)
		1:
			crown.position = Vector2(name_pos.x, name_pos.y - icon_size - 2)
		2:
			crown.position = Vector2(name_pos.x - icon_size - 5, name_pos.y)
		3:
			crown.position = Vector2(name_pos.x - icon_size - 5, name_pos.y)
		4:
			crown.position = Vector2(name_pos.x, name_pos.y - icon_size - 2)

	crown_nodes.append(crown)


func _hide_announcement() -> void:
	if _announcement_panel and is_instance_valid(_announcement_panel):
		_announcement_panel.queue_free()
		_announcement_panel = null


func _start_declarer_phase() -> void:
	var declarer: int = bidding_manager.get_declarer()
	var giruda: int = bidding_manager.states[declarer].bid_giruda
	var bid: int = bidding_manager.states[declarer].bid_count
	var dname: String = PLAYER_NAMES[declarer]

	var msg := "%s의 당선을 축하합니다!\n공약: %s %d\n\n나머지 4인은 %s의 독재 타도를 위해 뭉쳤다!\n그러나 4인 중 한 명은 %s의 숨겨진 심복이다..." % [dname, SUIT_DISPLAY.get(giruda, "?"), bid, dname, dname]
	_show_crown(declarer)
	_play_sfx(_sfx_elected)
	await _show_announcement_stay(msg)
	await get_tree().create_timer(1.0).timeout

	_resort_hand_with_giruda(giruda)
	await get_tree().create_timer(0.5).timeout
	await _move_kitty_to_declarer(declarer)
	await get_tree().create_timer(0.5).timeout
	_hide_announcement()

	if declarer != 0:
		await _bot_declarer_phase(declarer, giruda, bid)
	else:
		pass # TODO: player declarer phase


func _bot_declarer_phase(declarer: int, giruda: int, bid: int) -> void:
	await _show_announcement_stay("고민 중...")
	await get_tree().create_timer(2.0).timeout

	var dp = DeclarerPhaseScript.new(hands[declarer], kitty, bid, giruda)
	var bot_idx: int = declarer - 1
	bots[bot_idx].do_declarer_phase(dp)

	var final_giruda: int = dp.giruda
	var final_bid: int = dp.bid

	_hide_announcement()

	var card_size: Vector2 = CardUtilScript.get_card_size(get_viewport())
	for node in kitty_card_nodes:
		if is_instance_valid(node):
			node.queue_free()
	kitty_card_nodes.clear()

	for card in placed_cards.duplicate():
		if is_instance_valid(card):
			card.queue_free()
	placed_cards.clear()
	for p in range(5):
		if p == 0:
			continue
		var count: int = 10
		for i in range(count):
			var card: Control = _create_card_back(card_size)
			var pos: Vector2 = CardUtilScript.get_card_position(get_viewport(), p, i, count)
			_add_card(card, card_size, pos)
	for i in range(hands[0].size()):
		var card: Control = _create_card_front(CardUtilScript.get_my_card_size(get_viewport()), hands[0][i])
		var pos: Vector2 = CardUtilScript.get_card_position(get_viewport(), 0, i, hands[0].size())
		_add_card(card, CardUtilScript.get_my_card_size(get_viewport()), pos)
		p0_card_nodes.append({"node": card, "card_data": hands[0][i]})

	await get_tree().create_timer(0.3).timeout

	var friend_type: int = dp.friend_call_type
	var friend_text := ""
	var friend_card = null

	match friend_type:
		DeclarerPhaseScript.FriendCallType.CARD:
			friend_card = dp.friend_call_card
			if friend_card.is_joker:
				friend_text = "조커 프렌드"
			else:
				var card_str: String = "%s %s" % [SUIT_DISPLAY.get(_card_suit_to_giruda(friend_card.suit), "?"), _rank_name(friend_card.rank)]
				friend_text = "%s 프렌드" % card_str
		DeclarerPhaseScript.FriendCallType.FIRST_TRICK_WINNER:
			friend_text = "초구 프렌드"
		DeclarerPhaseScript.FriendCallType.NO_FRIEND:
			friend_text = "노프렌드"
		DeclarerPhaseScript.FriendCallType.PLAYER:
			friend_text = "%s 프렌드" % PLAYER_NAMES[dp.friend_call_player]

	var vh: float = get_viewport_rect().size.y
	var font_size: int = int(vh / 18.0)
	var small_font: int = int(vh / 22.0)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.75)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	panel.z_index = 110

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)

	var bid_label: Label = _create_label("공약: %s %d" % [SUIT_DISPLAY.get(final_giruda, "?"), final_bid], font_size, Color.WHITE)
	bid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(bid_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var friend_title: Label = _create_label("프렌드", small_font, Color(0.8, 0.8, 0.8))
	friend_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(friend_title)

	if friend_card:
		var friend_card_size: Vector2 = CardUtilScript.get_card_size(get_viewport())
		var card_img := TextureRect.new()
		card_img.texture = CardTextureScript.get_texture(friend_card)
		card_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_img.custom_minimum_size = friend_card_size
		card_img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(card_img)

	var friend_label: Label = _create_label(friend_text, font_size, Color.YELLOW)
	friend_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(friend_label)

	panel.add_child(vbox)
	add_child(panel)
	await get_tree().process_frame
	if friend_card:
		var card_img = vbox.get_child(3) if friend_card else null
		if card_img and card_img is TextureRect:
			card_img.size = CardUtilScript.get_card_size(get_viewport())
	await get_tree().process_frame
	panel.position = get_viewport_rect().size / 2.0 - panel.size / 2.0

	await get_tree().create_timer(3.5).timeout
	panel.queue_free()


func _card_suit_to_giruda(suit: int) -> int:
	match suit:
		CardScript.Suit.SPADE: return BiddingStateScript.Giruda.SPADE
		CardScript.Suit.DIAMOND: return BiddingStateScript.Giruda.DIAMOND
		CardScript.Suit.HEART: return BiddingStateScript.Giruda.HEART
		CardScript.Suit.CLUB: return BiddingStateScript.Giruda.CLUB
	return BiddingStateScript.Giruda.NONE


func _rank_name(rank: int) -> String:
	match rank:
		CardScript.Rank.ACE: return "A"
		CardScript.Rank.KING: return "K"
		CardScript.Rank.QUEEN: return "Q"
		CardScript.Rank.JACK: return "J"
	return str(rank)


func _resort_hand_with_giruda(giruda: int) -> void:
	var giruda_suit: int = -1
	match giruda:
		BiddingStateScript.Giruda.SPADE: giruda_suit = CardScript.Suit.SPADE
		BiddingStateScript.Giruda.DIAMOND: giruda_suit = CardScript.Suit.DIAMOND
		BiddingStateScript.Giruda.HEART: giruda_suit = CardScript.Suit.HEART
		BiddingStateScript.Giruda.CLUB: giruda_suit = CardScript.Suit.CLUB

	const BASE_SUIT_ORDER := {
		CardScript.Suit.SPADE: 0,
		CardScript.Suit.DIAMOND: 1,
		CardScript.Suit.HEART: 2,
		CardScript.Suit.CLUB: 3,
	}

	var sorted_hand: Array = hands[0].duplicate()
	sorted_hand.sort_custom(func(a, b):
		if a.is_joker:
			return true
		if b.is_joker:
			return false
		var a_order: int = 0 if a.suit == giruda_suit else BASE_SUIT_ORDER[a.suit] + 10
		var b_order: int = 0 if b.suit == giruda_suit else BASE_SUIT_ORDER[b.suit] + 10
		if a_order != b_order:
			return a_order < b_order
		return a.rank > b.rank
	)

	var sorted_nodes: Array = []
	for sorted_card in sorted_hand:
		for entry in p0_card_nodes:
			if not entry.has("used") and _cards_equal(entry["card_data"], sorted_card):
				sorted_nodes.append(entry["node"])
				entry["used"] = true
				break

	var tween: Tween = create_tween().set_parallel(true)
	for i in range(sorted_nodes.size()):
		var target_pos: Vector2 = CardUtilScript.get_card_position(get_viewport(), 0, i, sorted_hand.size())
		var node: Control = sorted_nodes[i]
		if is_instance_valid(node):
			node.z_index = i
			tween.tween_property(node, "position", target_pos, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

	hands[0] = sorted_hand
	for entry in p0_card_nodes:
		if entry.has("used"):
			entry.erase("used")


func _move_kitty_to_declarer(declarer: int) -> void:
	var card_size: Vector2 = CardUtilScript.get_card_size(get_viewport())
	var my_card_size: Vector2 = CardUtilScript.get_my_card_size(get_viewport())

	if declarer != 0:
		var existing_backs: Array = []
		for card in bot_hand_nodes[declarer]:
			if is_instance_valid(card):
				existing_backs.append(card)

		var center: Vector2 = CardUtilScript.get_center(get_viewport())
		var half_card: Vector2 = card_size / 2.0

		var tween: Tween = create_tween()
		for i in range(kitty_card_nodes.size()):
			var kitty_node = kitty_card_nodes[i]
			var new_total: int = 10 + i + 1
			if is_instance_valid(kitty_node):
				var mid_target: Vector2 = CardUtilScript.get_card_position(get_viewport(), declarer, new_total / 2, new_total)
				tween.tween_property(kitty_node, "position", mid_target, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
				tween.tween_property(kitty_node, "modulate:a", 0.0, 0.08)
				var capture_total: int = new_total
				tween.tween_callback(func():
					_play_sfx(_sfx_deal)
					kitty_node.queue_free()
					var new_back: Control = _create_card_back(card_size)
					var last_pos: Vector2 = CardUtilScript.get_card_position(get_viewport(), declarer, existing_backs.size(), capture_total)
					_add_card(new_back, card_size, last_pos)
					existing_backs.append(new_back)
					bot_hand_nodes[declarer].append(new_back)
					var reposition: Tween = create_tween().set_parallel(true)
					for j in range(existing_backs.size()):
						var back = existing_backs[j]
						if is_instance_valid(back):
							var pos: Vector2 = CardUtilScript.get_card_position(get_viewport(), declarer, j, capture_total)
							reposition.tween_property(back, "position", pos, 0.15)
				)
				tween.tween_interval(0.35)
		await tween.finished
	else:
		hands[0].append_array(kitty)
		var giruda: int = bidding_manager.states[0].bid_giruda

		var giruda_suit: int = -1
		match giruda:
			BiddingStateScript.Giruda.SPADE: giruda_suit = CardScript.Suit.SPADE
			BiddingStateScript.Giruda.DIAMOND: giruda_suit = CardScript.Suit.DIAMOND
			BiddingStateScript.Giruda.HEART: giruda_suit = CardScript.Suit.HEART
			BiddingStateScript.Giruda.CLUB: giruda_suit = CardScript.Suit.CLUB

		const SUIT_BASE := {
			CardScript.Suit.SPADE: 0,
			CardScript.Suit.DIAMOND: 1,
			CardScript.Suit.HEART: 2,
			CardScript.Suit.CLUB: 3,
		}
		var sorted_13: Array = hands[0].duplicate()
		sorted_13.sort_custom(func(a, b):
			if a.is_joker: return true
			if b.is_joker: return false
			var ao: int = 0 if a.suit == giruda_suit else SUIT_BASE[a.suit] + 10
			var bo: int = 0 if b.suit == giruda_suit else SUIT_BASE[b.suit] + 10
			if ao != bo: return ao < bo
			return a.rank > b.rank
		)
		hands[0] = sorted_13

		var existing_tween: Tween = create_tween().set_parallel(true)
		for entry in p0_card_nodes:
			var card_data = entry["card_data"]
			var node: Control = entry["node"]
			if not is_instance_valid(node):
				continue
			var idx: int = -1
			for j in range(13):
				if _cards_equal(sorted_13[j], card_data):
					idx = j
					break
			if idx >= 0:
				var pos: Vector2 = CardUtilScript.get_card_position(get_viewport(), 0, idx, 13)
				node.z_index = idx
				existing_tween.tween_property(node, "position", pos, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

		await existing_tween.finished
		await get_tree().create_timer(0.3).timeout

		var center: Vector2 = CardUtilScript.get_center(get_viewport())
		var half_card: Vector2 = my_card_size / 2.0
		var kitty_tween: Tween = create_tween()

		for i in range(3):
			var kitty_card = kitty[i]
			var sorted_idx: int = -1
			for j in range(13):
				if _cards_equal(sorted_13[j], kitty_card):
					sorted_idx = j
					break
			var target_pos: Vector2 = CardUtilScript.get_card_position(get_viewport(), 0, sorted_idx, 13)
			var raised_pos: Vector2 = target_pos + Vector2(0, -my_card_size.y * 0.15)

			kitty_tween.tween_callback(func():
				var card_node: Control = _create_card_front(my_card_size, kitty_card)
				_add_card(card_node, my_card_size, center - half_card)
				p0_card_nodes.append({"node": card_node, "card_data": kitty_card})
				var tw: Tween = create_tween()
				tw.tween_property(card_node, "position", raised_pos, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
				card_node.z_index = sorted_idx
				_play_sfx(_sfx_deal)
			)
			kitty_tween.tween_interval(0.4)
		await kitty_tween.finished


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

	tween.tween_callback(func(): _play_sfx(_sfx_shuffle))

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
		kitty_card_nodes.append(kitty_card)

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
				var is_first_in_bundle: bool = c == 0

				tween.tween_callback(func():
					if is_first_in_bundle:
						_play_sfx(_sfx_deal)
					var card: Control
					var sz: Vector2
					if is_p0:
						sz = my_card_size
						card = _create_card_front(sz, hands[0][p0_idx])
						p0_card_nodes.append({"node": card, "card_data": hands[0][p0_idx]})
					else:
						sz = card_size
						card = _create_card_back(sz)
						bot_hand_nodes[target_player].append(card)
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
	_play_sfx(_sfx_sort)
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
	tween.tween_interval(0.5)
	tween.tween_callback(_start_bidding)


var _bold_font: Font = null
var _sfx_shuffle: AudioStream = preload("res://assets/sounds/shuffle.wav")
var _sfx_deal: AudioStream = preload("res://assets/sounds/draw.wav")
var _sfx_play: AudioStream = preload("res://assets/sounds/playcard.wav")
var _sfx_sort: AudioStream = preload("res://assets/sounds/card-fan-1.ogg")
var _sfx_bid: AudioStream = preload("res://assets/sounds/bid.wav")
var _sfx_pass: AudioStream = preload("res://assets/sounds/pass.wav")
var _sfx_elected: AudioStream = preload("res://assets/sounds/elected.wav")


func _play_sfx(stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


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

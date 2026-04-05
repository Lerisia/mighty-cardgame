extends Control

const CardScript = preload("res://scripts/game_logic/card.gd")
const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")

const SUIT_NAMES := ["Spade", "Diamond", "Heart", "Club"]
const SUIT_VALUES := [CardScript.Suit.SPADE, CardScript.Suit.DIAMOND, CardScript.Suit.HEART, CardScript.Suit.CLUB]
const RANK_NAMES := ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
const RANK_VALUES := [
	CardScript.Rank.TWO, CardScript.Rank.THREE, CardScript.Rank.FOUR, CardScript.Rank.FIVE,
	CardScript.Rank.SIX, CardScript.Rank.SEVEN, CardScript.Rank.EIGHT, CardScript.Rank.NINE,
	CardScript.Rank.TEN, CardScript.Rank.JACK, CardScript.Rank.QUEEN, CardScript.Rank.KING,
	CardScript.Rank.ACE,
]

var _controls: Dictionary = {}


func _ready() -> void:
	_build_ui()
	_load_from_options()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.1, 0.12, 0.18, 1)
	add_child(bg)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	add_child(root_vbox)

	var title := Label.new()
	title.text = "Options"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	root_vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	root_vbox.add_child(spacer)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(tabs)

	tabs.add_child(_build_bidding_tab())
	tabs.add_child(_build_friend_tab())
	tabs.add_child(_build_special_cards_tab())
	tabs.add_child(_build_scoring_tab())
	tabs.add_child(_build_deal_miss_tab())
	tabs.add_child(_build_display_tab())

	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size = Vector2(0, 40)
	root_vbox.add_child(bottom)

	var reset_btn := Button.new()
	reset_btn.text = "Reset to Defaults"
	reset_btn.pressed.connect(_on_reset)
	bottom.add_child(reset_btn)

	var hspacer := Control.new()
	hspacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(hspacer)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.pressed.connect(_on_back)
	bottom.add_child(back_btn)


func _build_bidding_tab() -> ScrollContainer:
	var scroll := _make_tab("Bidding")
	var vbox: VBoxContainer = scroll.get_child(0)
	_add_int_option(vbox, "Minimum Bid", "min_bid", 11, 20)
	_add_bool_option(vbox, "Allow Giruda Change Before Kitty", "allow_giruda_change_before_kitty")
	_add_bool_option(vbox, "Allow Giruda Change After Kitty", "allow_giruda_change_after_kitty")
	_add_bool_option(vbox, "Bid 20 Run Extra Double", "bid_20_run_double")
	return scroll


func _build_friend_tab() -> ScrollContainer:
	var scroll := _make_tab("Friend")
	var vbox: VBoxContainer = scroll.get_child(0)
	_add_bool_option(vbox, "Allow Player Friend", "allow_player_friend")
	_add_bool_option(vbox, "Allow Fake Friend", "allow_fake_friend")
	_add_bool_option(vbox, "Last Trick Friend", "allow_last_trick_friend")
	return scroll


func _build_special_cards_tab() -> ScrollContainer:
	var scroll := _make_tab("Special Cards")
	var vbox: VBoxContainer = scroll.get_child(0)

	_add_section_label(vbox, "Alternate Mighty (when Spade is giruda)")
	_add_suit_option(vbox, "Suit", "alter_mighty_suit")
	_add_rank_option(vbox, "Rank", "alter_mighty_rank")

	_add_section_label(vbox, "Alternate Joker Call (when Club is giruda)")
	_add_suit_option(vbox, "Suit", "alter_joker_call_suit")
	_add_rank_option(vbox, "Rank", "alter_joker_call_rank")

	_add_section_label(vbox, "Mighty Effect")
	_add_bool_option(vbox, "First Trick", "first_trick_mighty_effect")
	_add_bool_option(vbox, "Last Trick", "last_trick_mighty_effect")

	_add_section_label(vbox, "Joker Effect")
	_add_bool_option(vbox, "First Trick", "first_trick_joker_effect")
	_add_bool_option(vbox, "Last Trick", "last_trick_joker_effect")
	_add_bool_option(vbox, "When Joker Called", "joker_called_joker_effect")
	return scroll


func _build_scoring_tab() -> ScrollContainer:
	var scroll := _make_tab("Scoring")
	var vbox: VBoxContainer = scroll.get_child(0)
	_add_enum_option(vbox, "Back Run Method", "back_run_method",
		["Ruling Party 10 or Less", "Opposition Gets Bid or More"])
	return scroll


func _build_deal_miss_tab() -> ScrollContainer:
	var scroll := _make_tab("Deal Miss")
	var vbox: VBoxContainer = scroll.get_child(0)

	_add_section_label(vbox, "Penalty")
	_add_enum_option(vbox, "Penalty Method", "deal_miss_penalty_method",
		["Fixed", "Doubling"])
	_add_int_option(vbox, "Fixed Penalty", "deal_miss_fixed_penalty", 1, 50)
	_add_int_option(vbox, "Doubling Base", "deal_miss_doubling_base", 1, 20)
	_add_bool_option(vbox, "Dealer Changes to Declarer", "deal_miss_dealer_to_declarer")

	_add_section_label(vbox, "Threshold")
	_add_float_option(vbox, "Threshold Score", "deal_miss_threshold", 0.0, 20.0, 0.5)
	_add_enum_option(vbox, "Comparison", "deal_miss_threshold_type",
		["Less Than", "Less or Equal"])

	_add_section_label(vbox, "Card Scores")
	_add_float_option(vbox, "Joker", "deal_miss_joker_score", -5.0, 5.0, 0.5)
	_add_float_option(vbox, "Mighty", "deal_miss_mighty_score", -5.0, 5.0, 0.5)
	_add_float_option(vbox, "Ten", "deal_miss_ten_score", -5.0, 5.0, 0.5)
	_add_float_option(vbox, "Point Card (J/Q/K/A)", "deal_miss_point_card_score", -5.0, 5.0, 0.5)
	_add_float_option(vbox, "Non-Point Card", "deal_miss_non_point_score", -5.0, 5.0, 0.5)
	return scroll


func _build_display_tab() -> ScrollContainer:
	var scroll := _make_tab("Display")
	var vbox: VBoxContainer = scroll.get_child(0)
	_add_enum_option(vbox, "Suit Display Style", "suit_display_style",
		["English (Heart, Spade...)", "Korean (트, 삽...)"])
	return scroll


# --- Helpers ---

func _make_tab(tab_name: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)
	return scroll


func _add_section_label(parent: VBoxContainer, text: String) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	parent.add_child(spacer)
	var lbl := Label.new()
	lbl.text = "-- %s --" % text
	lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	parent.add_child(lbl)


func _add_bool_option(parent: VBoxContainer, label_text: String, key: String) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)
	var cb := CheckBox.new()
	hbox.add_child(cb)
	_controls[key] = cb


func _add_int_option(parent: VBoxContainer, label_text: String, key: String, min_val: int, max_val: int) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)
	var spin := SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = 1
	spin.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(spin)
	_controls[key] = spin


func _add_float_option(parent: VBoxContainer, label_text: String, key: String, min_val: float, max_val: float, step: float) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)
	var spin := SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = step
	spin.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(spin)
	_controls[key] = spin


func _add_enum_option(parent: VBoxContainer, label_text: String, key: String, names: Array) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)
	var opt := OptionButton.new()
	for i in range(names.size()):
		opt.add_item(names[i], i)
	opt.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(opt)
	_controls[key] = opt


func _add_suit_option(parent: VBoxContainer, label_text: String, key: String) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)
	var opt := OptionButton.new()
	for i in range(SUIT_NAMES.size()):
		opt.add_item(SUIT_NAMES[i], SUIT_VALUES[i])
	opt.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(opt)
	_controls[key] = {"control": opt, "values": SUIT_VALUES}


func _add_rank_option(parent: VBoxContainer, label_text: String, key: String) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)
	var opt := OptionButton.new()
	for i in range(RANK_NAMES.size()):
		opt.add_item(RANK_NAMES[i], RANK_VALUES[i])
	opt.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(opt)
	_controls[key] = {"control": opt, "values": RANK_VALUES}


# --- Load/Save ---

func _load_from_options() -> void:
	var opts = OptionsManager.options
	for key in _controls:
		var ctrl = _controls[key]
		var val = opts.get(key)
		if ctrl is CheckBox:
			ctrl.button_pressed = val
		elif ctrl is SpinBox:
			ctrl.value = val
		elif ctrl is OptionButton:
			_select_enum_value(ctrl, val)
		elif ctrl is Dictionary:
			var opt_btn: OptionButton = ctrl["control"]
			var values: Array = ctrl["values"]
			var idx := values.find(val)
			if idx >= 0:
				opt_btn.selected = idx


func _save_to_options() -> void:
	var opts = OptionsManager.options
	for key in _controls:
		var ctrl = _controls[key]
		if ctrl is CheckBox:
			opts.set(key, ctrl.button_pressed)
		elif ctrl is SpinBox:
			var field_type := _get_field_type(key)
			if field_type == "int":
				opts.set(key, int(ctrl.value))
			else:
				opts.set(key, ctrl.value)
		elif ctrl is OptionButton:
			opts.set(key, ctrl.get_selected_id())
		elif ctrl is Dictionary:
			var opt_btn: OptionButton = ctrl["control"]
			var values: Array = ctrl["values"]
			var idx := opt_btn.selected
			if idx >= 0 and idx < values.size():
				opts.set(key, values[idx])
	OptionsManager.save_options()


func _select_enum_value(opt: OptionButton, val: int) -> void:
	for i in range(opt.get_item_count()):
		if opt.get_item_id(i) == val:
			opt.selected = i
			return


func _get_field_type(key: String) -> String:
	for field in OptionsManager.FIELDS:
		if field[1] == key:
			return field[2]
	return "float"


# --- Buttons ---

func _on_back() -> void:
	_save_to_options()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_reset() -> void:
	OptionsManager.reset_to_defaults()
	_load_from_options()

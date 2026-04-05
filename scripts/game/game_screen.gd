extends Control

const RoundManagerScript = preload("res://scripts/game_logic/round_manager.gd")
const BotManagerScript = preload("res://scripts/ai/bot_manager.gd")
const BSWStrategyScript = preload("res://scripts/ai/bsw_strategy.gd")
const XiaoStrategyScript = preload("res://scripts/ai/xiao_strategy.gd")
const PlayerScript = preload("res://scripts/game_logic/player.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")
const CardTextureScript = preload("res://scripts/ui/card_texture.gd")

var players: Array = []
var bots: Array = []
var round_manager = null
var dealer: int = 0

var player_nodes: Array = []

enum State { IDLE, DEALING, BIDDING, DECLARER, PLAYING, SCORING }
var state: int = State.IDLE


func _ready() -> void:
	player_nodes = [
		null,
		$PlayerTopLeft,
		$PlayerTopRight,
		$PlayerRight,
		$PlayerLeft,
	]

	for i in range(5):
		players.append(PlayerScript.new("Player %d" % i, i, true))
		if i % 2 == 0:
			bots.append(BotManagerScript.new(BSWStrategyScript.new(), i))
		else:
			bots.append(BotManagerScript.new(XiaoStrategyScript.new(), i))

	$StepTimer.timeout.connect(_on_step)
	_start_round()


func _start_round() -> void:
	round_manager = RoundManagerScript.new(players, dealer, 13)
	round_manager.do_deal()
	state = State.BIDDING
	_update_display()
	_set_status("Dealing cards...")
	$StepTimer.start()


func _on_step() -> void:
	match state:
		State.BIDDING:
			_step_bidding()
		State.DECLARER:
			_step_declarer()
		State.PLAYING:
			_step_playing()
		State.SCORING:
			_step_scoring()


func _step_bidding() -> void:
	if round_manager.bidding_manager.is_finished():
		round_manager.advance_from_bidding()
		state = State.DECLARER
		var di: int = round_manager.declarer_index
		var bid: int = round_manager.bid
		var giruda_name: String = _giruda_name(round_manager.giruda)
		_set_status("Player %d declares %d %s" % [di, bid, giruda_name])
		_update_display()
		$StepTimer.start()
		return

	var turn: int = round_manager.bidding_manager.current_turn
	var before_bid: int = round_manager.bidding_manager.highest_bid
	bots[turn].do_bidding_turn(round_manager.bidding_manager)
	var after_bid: int = round_manager.bidding_manager.highest_bid

	if round_manager.bidding_manager.states[turn].passed:
		_set_status("Player %d passes" % turn)
	elif after_bid > before_bid:
		var g: int = round_manager.bidding_manager.states[turn].bid_giruda
		_set_status("Player %d bids %d %s" % [turn, after_bid, _giruda_name(g)])

	_update_display()
	$StepTimer.start()


func _step_declarer() -> void:
	var di: int = round_manager.declarer_index
	bots[di].do_declarer_phase(round_manager.declarer_phase)
	round_manager.advance_from_declarer()
	state = State.PLAYING

	var friend_type: int = round_manager.declarer_phase.friend_call_type
	if friend_type == DeclarerPhaseScript.FriendCallType.NO_FRIEND:
		_set_status("No friend declared. Game starts!")
	elif friend_type == DeclarerPhaseScript.FriendCallType.CARD:
		_set_status("Friend: %s holder. Game starts!" % round_manager.declarer_phase.friend_call_card.to_string())
	elif friend_type == DeclarerPhaseScript.FriendCallType.FIRST_TRICK_WINNER:
		_set_status("Friend: first trick winner. Game starts!")
	else:
		_set_status("Game starts!")

	_update_display()
	$StepTimer.start()


func _step_playing() -> void:
	if round_manager.trick_manager.is_game_over():
		round_manager.advance_from_play()
		state = State.SCORING
		_set_status("All tricks played. Scoring...")
		_update_display()
		$StepTimer.start()
		return

	var tm = round_manager.trick_manager
	var turn: int = tm.current_turn
	var before_count: int = tm.current_trick.size()
	bots[turn].do_trick_turn(tm)

	if tm.current_trick.size() > before_count:
		var played_card = tm.current_trick[tm.current_trick.size() - 1]
		_set_status("Player %d plays %s" % [turn, played_card.to_string()])
	elif tm.current_trick.size() == 0:
		_set_status("Trick %d won by Player %d" % [tm.trick_number, tm.last_trick_winner])

	_update_display()
	$StepTimer.start()


func _step_scoring() -> void:
	round_manager.calculate_scores()
	var score_text := "Scores: "
	for i in range(5):
		score_text += "P%d=%d " % [i, players[i].score]
	_set_status(score_text)
	state = State.IDLE
	_update_display()


func _update_display() -> void:
	_update_player_displays()
	_update_center()
	_update_my_hand()


func _update_player_displays() -> void:
	for i in range(1, 5):
		var node = player_nodes[i]
		if node == null:
			continue
		node.get_node("Name").text = players[i].player_name
		var card_count := 0
		if round_manager and round_manager.trick_manager:
			card_count = round_manager.trick_manager.states[i].hand.size()
		elif round_manager and round_manager.phase == RoundManagerScript.Phase.BIDDING:
			card_count = round_manager.bidding_manager.hands[i].size()
		node.get_node("Cards").text = "[%d cards]" % card_count

		var points_text := ""
		if round_manager and round_manager.trick_manager:
			var pt_cards: Array = round_manager.trick_manager.states[i].point_cards
			if pt_cards.size() > 0:
				var names := []
				for c in pt_cards:
					names.append(c.to_string())
				points_text = " ".join(names)
		node.get_node("Points").text = points_text


func _update_center() -> void:
	if not round_manager:
		return

	var info_text := ""
	if round_manager.giruda != BiddingStateScript.Giruda.NONE:
		info_text = "Giruda: %s | Bid: %d" % [_giruda_name(round_manager.giruda), round_manager.bid]
	$CenterInfo/GameInfo.text = info_text

	for child in $CenterInfo/TrickCards.get_children():
		child.queue_free()

	if round_manager.trick_manager:
		var tm = round_manager.trick_manager
		for j in range(tm.current_trick.size()):
			var vbox := VBoxContainer.new()
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			var label := Label.new()
			label.text = "P%d" % tm.current_trick_players[j]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var tex_rect := TextureRect.new()
			tex_rect.texture = CardTextureScript.get_texture(tm.current_trick[j])
			tex_rect.custom_minimum_size = Vector2(50, 70)
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			vbox.add_child(label)
			vbox.add_child(tex_rect)
			$CenterInfo/TrickCards.add_child(vbox)
		$CenterInfo/TrickInfo.text = "Trick %d/10" % (tm.trick_number + 1)
	else:
		$CenterInfo/TrickInfo.text = ""


func _update_my_hand() -> void:
	for child in $MyHand.get_children():
		child.queue_free()

	var hand: Array = []
	if round_manager and round_manager.trick_manager:
		hand = round_manager.trick_manager.states[0].hand
	elif round_manager and round_manager.phase == RoundManagerScript.Phase.BIDDING:
		hand = round_manager.hands[0]

	for card in hand:
		var btn := TextureButton.new()
		btn.texture_normal = CardTextureScript.get_texture(card)
		btn.custom_minimum_size = Vector2(60, 84)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.ignore_texture_size = true
		$MyHand.add_child(btn)


func _set_status(text: String) -> void:
	$StatusLabel.text = text


func _giruda_name(giruda: int) -> String:
	match giruda:
		BiddingStateScript.Giruda.SPADE: return "Spade"
		BiddingStateScript.Giruda.DIAMOND: return "Diamond"
		BiddingStateScript.Giruda.HEART: return "Heart"
		BiddingStateScript.Giruda.CLUB: return "Club"
		BiddingStateScript.Giruda.NO_GIRUDA: return "No Giruda"
	return "?"

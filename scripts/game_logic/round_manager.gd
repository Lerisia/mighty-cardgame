class_name RoundManager
extends RefCounted

const DeckScript = preload("res://scripts/game_logic/deck.gd")
const PlayStateScript = preload("res://scripts/game_logic/play_state.gd")
const BiddingManagerScript = preload("res://scripts/game_logic/bidding_manager.gd")
const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")
const TrickManagerScript = preload("res://scripts/game_logic/trick_manager.gd")
const ScoreCalcScript = preload("res://scripts/game_logic/score_calculator.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")

enum Phase { DEAL, BIDDING, DECLARER, PLAY, SCORING, FINISHED }

var players: Array
var dealer_index: int
var min_bid: int
var phase: int = Phase.DEAL

var kitty: Array = []
var hands: Array = []
var bidding_manager = null
var declarer_phase = null
var trick_manager = null

var declarer_index: int = -1
var bid: int = 0
var giruda: int = BiddingStateScript.Giruda.NONE
var friend_call: Dictionary = {}
var no_friend: bool = false


func _init(p_players: Array, p_dealer: int, p_min_bid: int) -> void:
	players = p_players
	dealer_index = p_dealer
	min_bid = p_min_bid


func do_deal() -> void:
	if phase != Phase.DEAL:
		return
	var deck = DeckScript.new()
	var result: Dictionary = deck.deal(players.size())
	hands = result["hands"]
	kitty = result["kitty"]

	var bidding_hands := []
	for hand in hands:
		bidding_hands.append(hand.duplicate())

	bidding_manager = BiddingManagerScript.new(players.size(), dealer_index, bidding_hands, min_bid)
	phase = Phase.BIDDING


func advance_from_bidding() -> bool:
	if phase != Phase.BIDDING:
		return false
	if not bidding_manager.is_finished():
		return false

	declarer_index = bidding_manager.get_declarer()
	bid = bidding_manager.states[declarer_index].bid_count
	giruda = bidding_manager.states[declarer_index].bid_giruda

	declarer_phase = DeclarerPhaseScript.new(hands[declarer_index], kitty, bid, giruda)
	phase = Phase.DECLARER
	return true


func advance_from_declarer() -> bool:
	if phase != Phase.DECLARER:
		return false
	if not declarer_phase.is_finished:
		return false

	bid = declarer_phase.bid
	giruda = declarer_phase.giruda
	friend_call = {
		"type": declarer_phase.friend_call_type,
	}
	if declarer_phase.friend_call_type == DeclarerPhaseScript.FriendCallType.CARD:
		friend_call["card"] = declarer_phase.friend_call_card
	elif declarer_phase.friend_call_type == DeclarerPhaseScript.FriendCallType.PLAYER:
		friend_call["player_index"] = declarer_phase.friend_call_player

	no_friend = declarer_phase.friend_call_type == DeclarerPhaseScript.FriendCallType.NO_FRIEND

	hands[declarer_index] = declarer_phase.hand

	var states := []
	for i in range(players.size()):
		var st = PlayStateScript.new()
		st.hand = hands[i]
		states.append(st)
	states[declarer_index].set_discarded(declarer_phase.discarded)

	trick_manager = TrickManagerScript.new(states, declarer_index, giruda, friend_call)
	trick_manager.face_down_pile.append_array(declarer_phase.discarded)

	phase = Phase.PLAY
	return true


func advance_from_play() -> bool:
	if phase != Phase.PLAY:
		return false
	if not trick_manager.is_game_over():
		return false
	phase = Phase.SCORING
	return true


func calculate_scores() -> bool:
	if phase != Phase.SCORING:
		return false

	var opposition_points := 0
	for i in range(players.size()):
		if not trick_manager._is_ruling_party(i):
			opposition_points += trick_manager.states[i].get_point_count()

	var ruling_points: int = 20 - opposition_points
	var is_no_giruda: bool = giruda == BiddingStateScript.Giruda.NO_GIRUDA

	var result: Dictionary = ScoreCalcScript.calculate(bid, ruling_points, min_bid, no_friend, is_no_giruda, false)

	for i in range(players.size()):
		if i == declarer_index:
			players[i].add_score(result["declarer"])
		elif trick_manager.friend_revealed and i == trick_manager.friend_index:
			players[i].add_score(result["friend"])
		else:
			players[i].add_score(result["opposition"])

	phase = Phase.FINISHED
	return true

class_name ScoreCalculator
extends RefCounted

const GameOptionsScript = preload("res://scripts/game_logic/game_options.gd")

const TOTAL_POINTS := 20
const BACK_RUN_THRESHOLD := 10


static func calculate(bid: int, ruling_points: int, min_bid: int, no_friend: bool, no_giruda: bool, bid_20_run_option: bool) -> Dictionary:
	var opts = GameOptionsScript.new()
	opts.bid_20_run_double = bid_20_run_option
	return calculate_with_options(bid, ruling_points, min_bid, no_friend, no_giruda, opts)


static func calculate_with_options(bid: int, ruling_points: int, min_bid: int, no_friend: bool, no_giruda: bool, options: GameOptionsScript) -> Dictionary:
	var declarer_won: bool = ruling_points >= bid
	var is_run: bool = ruling_points == TOTAL_POINTS and declarer_won

	var multiplier := 1
	if is_run:
		multiplier *= 2
	if no_giruda and declarer_won:
		multiplier *= 2
	if options.bid_20_run_double and bid == TOTAL_POINTS and is_run:
		multiplier *= 2

	var back_run := false

	if declarer_won:
		var base: int = ((bid - min_bid) * 2 + (ruling_points - bid)) * multiplier
		if no_friend:
			var result := _no_friend_win(base)
			result["back_run"] = false
			return result
		var result := _friend_win(base)
		result["back_run"] = false
		return result
	else:
		back_run = _is_back_run(ruling_points, bid, options)
		if back_run:
			multiplier *= 2
		var base: int = (bid - ruling_points) * multiplier
		if no_friend:
			var result := _no_friend_lose(base)
			result["back_run"] = back_run
			return result
		var result := _friend_lose(base)
		result["back_run"] = back_run
		return result


static func _is_back_run(ruling_points: int, bid: int, options: GameOptionsScript) -> bool:
	var opposition_points: int = TOTAL_POINTS - ruling_points
	match options.back_run_method:
		GameOptionsScript.BackRunMethod.RULING_PARTY_10_OR_LESS:
			return ruling_points <= BACK_RUN_THRESHOLD
		GameOptionsScript.BackRunMethod.OPPOSITION_GETS_BID_OR_MORE:
			return opposition_points >= bid
	return false


static func _friend_win(base: int) -> Dictionary:
	return {
		"declarer": base * 2,
		"friend": base,
		"opposition": -base,
	}


static func _friend_lose(base: int) -> Dictionary:
	return {
		"declarer": -base * 2,
		"friend": -base,
		"opposition": base,
	}


static func _no_friend_win(base: int) -> Dictionary:
	return {
		"declarer": base * 4,
		"friend": 0,
		"opposition": -base,
	}


static func _no_friend_lose(base: int) -> Dictionary:
	return {
		"declarer": -base * 4,
		"friend": 0,
		"opposition": base,
	}

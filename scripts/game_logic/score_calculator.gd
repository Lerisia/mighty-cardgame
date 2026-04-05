class_name ScoreCalculator
extends RefCounted

const TOTAL_POINTS := 20


static func calculate(bid: int, ruling_points: int, min_bid: int, no_friend: bool, no_giruda: bool, bid_20_run_option: bool) -> Dictionary:
	var declarer_won: bool = ruling_points >= bid
	var is_run: bool = ruling_points == TOTAL_POINTS and declarer_won

	var multiplier := 1
	if is_run:
		multiplier *= 2
	if no_giruda and declarer_won:
		multiplier *= 2
	if bid_20_run_option and bid == TOTAL_POINTS and is_run:
		multiplier *= 2

	if declarer_won:
		var base: int = ((bid - min_bid) * 2 + (ruling_points - bid)) * multiplier
		if no_friend:
			return _no_friend_win(base)
		return _friend_win(base)
	else:
		var base: int = (bid - ruling_points) * multiplier
		if no_friend:
			return _no_friend_lose(base)
		return _friend_lose(base)


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

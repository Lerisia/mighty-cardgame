class_name BiddingState
extends RefCounted

enum Giruda { NONE, SPADE, DIAMOND, HEART, CLUB, NO_GIRUDA }

const MIN_BID := 11
const MAX_BID := 20

var passed: bool = false
var bid_count: int = 0
var bid_giruda: Giruda = Giruda.NONE


func place_bid(count: int, giruda: Giruda) -> bool:
	if passed:
		return false
	if count < MIN_BID or count > MAX_BID:
		return false
	bid_count = count
	bid_giruda = giruda
	return true


func pass_bid() -> void:
	passed = true

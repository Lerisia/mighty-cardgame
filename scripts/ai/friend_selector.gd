class_name FriendSelector
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const CardValidatorScript = preload("res://scripts/game_logic/card_validator.gd")
const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")


static func select(hand: Array, giruda: int, joker_friend_allowed: bool = true) -> Dictionary:
	var mighty = _get_mighty(giruda)
	var giruda_suit: int = _giruda_to_suit(giruda)
	var found_card = null

	while true:
		if not _hand_contains(hand, mighty):
			found_card = mighty
			break

		if joker_friend_allowed:
			var joker = CardScript.create_joker()
			if not _hand_contains(hand, joker):
				found_card = joker
				break

		if giruda_suit >= 0:
			var kiruda_ace = CardScript.new(giruda_suit, CardScript.Rank.ACE)
			if not _hand_contains(hand, kiruda_ace):
				found_card = kiruda_ace
				break

			var kiruda_king = CardScript.new(giruda_suit, CardScript.Rank.KING)
			if not _hand_contains(hand, kiruda_king):
				found_card = kiruda_king
				break

		var found_other_ace: bool = false
		for suit in [CardScript.Suit.SPADE, CardScript.Suit.DIAMOND, CardScript.Suit.HEART, CardScript.Suit.CLUB]:
			var ace = CardScript.new(suit, CardScript.Rank.ACE)
			if not _hand_contains(hand, ace):
				found_card = ace
				found_other_ace = true
				break
		if found_other_ace:
			break

		if giruda_suit >= 0:
			var kiruda_queen = CardScript.new(giruda_suit, CardScript.Rank.QUEEN)
			if not _hand_contains(hand, kiruda_queen):
				found_card = kiruda_queen
				break

		break

	if found_card != null:
		return {
			"type": DeclarerPhaseScript.FriendCallType.CARD,
			"card": found_card,
		}

	return {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}


static func _hand_contains(hand: Array, target) -> bool:
	for card in hand:
		if target.is_joker and card.is_joker:
			return true
		if not target.is_joker and not card.is_joker:
			if card.suit == target.suit and card.rank == target.rank:
				return true
	return false


static func _get_mighty(giruda: int):
	if giruda == BiddingStateScript.Giruda.SPADE:
		return CardScript.new(CardScript.Suit.DIAMOND, CardScript.Rank.ACE)
	return CardScript.new(CardScript.Suit.SPADE, CardScript.Rank.ACE)


static func _giruda_to_suit(giruda: int) -> int:
	match giruda:
		BiddingStateScript.Giruda.SPADE: return CardScript.Suit.SPADE
		BiddingStateScript.Giruda.DIAMOND: return CardScript.Suit.DIAMOND
		BiddingStateScript.Giruda.HEART: return CardScript.Suit.HEART
		BiddingStateScript.Giruda.CLUB: return CardScript.Suit.CLUB
	return -1

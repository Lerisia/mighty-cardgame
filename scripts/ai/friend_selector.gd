class_name FriendSelector
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")
const BiddingStateScript = preload("res://scripts/game_logic/bidding_state.gd")
const CardValidatorScript = preload("res://scripts/game_logic/card_validator.gd")
const DeclarerPhaseScript = preload("res://scripts/game_logic/declarer_phase.gd")


static func select(hand: Array, giruda: int) -> Dictionary:
	var candidates: Array = _build_candidates(hand, giruda)

	for card in candidates:
		if not _hand_contains(hand, card):
			return {
				"type": DeclarerPhaseScript.FriendCallType.CARD,
				"card": card,
			}

	return {"type": DeclarerPhaseScript.FriendCallType.NO_FRIEND}


static func _build_candidates(hand: Array, giruda: int) -> Array:
	var candidates := []

	# 1. Mighty
	candidates.append(_get_mighty(giruda))

	# 2. Joker
	candidates.append(CardScript.create_joker())

	# 3. Giruda Ace
	var giruda_suit: int = _giruda_to_suit(giruda)
	if giruda != BiddingStateScript.Giruda.NO_GIRUDA:
		candidates.append(CardScript.new(giruda_suit, CardScript.Rank.ACE))

	# 4. Giruda King
	if giruda != BiddingStateScript.Giruda.NO_GIRUDA:
		candidates.append(CardScript.new(giruda_suit, CardScript.Rank.KING))

	# 5. Other Aces
	for suit in [CardScript.Suit.SPADE, CardScript.Suit.DIAMOND, CardScript.Suit.HEART, CardScript.Suit.CLUB]:
		var ace = CardScript.new(suit, CardScript.Rank.ACE)
		if not CardValidatorScript.is_mighty(ace, giruda):
			if giruda == BiddingStateScript.Giruda.NO_GIRUDA or suit != giruda_suit:
				candidates.append(ace)

	# 6. Giruda Queen
	if giruda != BiddingStateScript.Giruda.NO_GIRUDA:
		candidates.append(CardScript.new(giruda_suit, CardScript.Rank.QUEEN))

	return candidates


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

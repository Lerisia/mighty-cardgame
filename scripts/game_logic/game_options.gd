class_name GameOptions
extends RefCounted

const CardScript = preload("res://scripts/game_logic/card.gd")

# === Bidding ===

var min_bid: int = 13
var allow_giruda_change_before_kitty: bool = true
var allow_giruda_change_after_kitty: bool = true
var bid_20_run_double: bool = false

# === Friend ===

var allow_player_friend: bool = true
var allow_fake_friend: bool = false
var allow_last_trick_friend: bool = false

# === Special Cards ===

var alter_mighty_suit: int = CardScript.Suit.DIAMOND
var alter_mighty_rank: int = CardScript.Rank.ACE

var alter_joker_call_suit: int = CardScript.Suit.SPADE
var alter_joker_call_rank: int = CardScript.Rank.THREE

var first_trick_mighty_effect: bool = true
var last_trick_mighty_effect: bool = true
var first_trick_joker_effect: bool = false
var last_trick_joker_effect: bool = false
var joker_called_joker_effect: bool = false

# === Scoring ===

enum BackRunMethod { RULING_PARTY_10_OR_LESS, OPPOSITION_GETS_BID_OR_MORE }

var back_run_method: int = BackRunMethod.RULING_PARTY_10_OR_LESS

# === Deal Miss ===

enum DealMissPenalty { FIXED, DOUBLING }
enum DealMissThreshold { LESS_THAN, LESS_OR_EQUAL }

var deal_miss_penalty_method: int = DealMissPenalty.DOUBLING
var deal_miss_fixed_penalty: int = 5
var deal_miss_doubling_base: int = 2
var deal_miss_dealer_to_declarer: bool = true

var deal_miss_threshold: float = 1.0
var deal_miss_threshold_type: int = DealMissThreshold.LESS_THAN

var deal_miss_joker_score: float = -1.0
var deal_miss_mighty_score: float = 0.0
var deal_miss_ten_score: float = 0.5
var deal_miss_point_card_score: float = 1.0
var deal_miss_non_point_score: float = 0.0

# === Display ===

enum SuitDisplay { ENGLISH, KOREAN, SHORT_KOREAN }

var suit_display_style: int = SuitDisplay.ENGLISH

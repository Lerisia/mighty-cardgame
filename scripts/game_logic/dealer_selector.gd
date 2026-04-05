class_name DealerSelector
extends RefCounted


static func first_game(player_count: int) -> int:
	return randi() % player_count


static func next_dealer(ruling_party_won: bool, declarer_index: int, friend_index: int) -> int:
	if ruling_party_won:
		return declarer_index
	if friend_index < 0:
		return declarer_index
	return friend_index

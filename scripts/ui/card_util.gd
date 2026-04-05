class_name CardUtil
extends RefCounted

const CARD_ASPECT := 500.0 / 726.0
const CARD_OVERLAP_H := 0.3
const CARD_OVERLAP_V := 0.25
const MY_CARD_OVERLAP_H := 0.45


static func get_card_height(viewport: Viewport) -> float:
	return viewport.get_visible_rect().size.y / 5.0


static func get_card_size(viewport: Viewport) -> Vector2:
	var h: float = get_card_height(viewport)
	return Vector2(h * CARD_ASPECT, h)


static func get_center(viewport: Viewport) -> Vector2:
	var vp: Vector2 = viewport.get_visible_rect().size
	return vp / 2.0


static func get_hand_origin(viewport: Viewport, player_index: int) -> Vector2:
	var vp: Vector2 = viewport.get_visible_rect().size
	var cs: Vector2 = get_card_size(viewport)
	match player_index:
		0: return Vector2(vp.x / 2.0 - _my_hand_width(cs, 10) / 2.0, vp.y - cs.y - 10)
		1: return Vector2(5, vp.y * 0.25)
		2: return Vector2(vp.x * 0.05, -cs.y * 0.5)
		3: return Vector2(vp.x * 0.95 - _hand_width(cs, 10), -cs.y * 0.5)
		4: return Vector2(vp.x - cs.x - 5, vp.y * 0.25)
	return Vector2.ZERO


static func is_vertical(player_index: int) -> bool:
	return player_index == 1 or player_index == 4


static func get_card_position(viewport: Viewport, player_index: int, card_index: int, total_cards: int) -> Vector2:
	var origin: Vector2 = get_hand_origin(viewport, player_index)
	var cs: Vector2 = get_card_size(viewport)
	if is_vertical(player_index):
		var step: float = cs.y * CARD_OVERLAP_V
		return origin + Vector2(0, card_index * step)
	elif player_index == 0:
		var step: float = cs.x * MY_CARD_OVERLAP_H
		return origin + Vector2(card_index * step, 0)
	else:
		var step: float = cs.x * CARD_OVERLAP_H
		return origin + Vector2(card_index * step, 0)


static func _hand_width(card_size: Vector2, num_cards: int) -> float:
	return card_size.x + (num_cards - 1) * card_size.x * CARD_OVERLAP_H


static func _my_hand_width(card_size: Vector2, num_cards: int) -> float:
	return card_size.x + (num_cards - 1) * card_size.x * MY_CARD_OVERLAP_H

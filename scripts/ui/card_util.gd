class_name CardUtil
extends RefCounted

const CARD_ASPECT := 500.0 / 726.0


static func get_card_height(viewport: Viewport) -> float:
	return viewport.get_visible_rect().size.y / 5.0


static func get_card_size(viewport: Viewport) -> Vector2:
	var h: float = get_card_height(viewport)
	return Vector2(h * CARD_ASPECT, h)


static func get_center(viewport: Viewport) -> Vector2:
	var vp: Vector2 = viewport.get_visible_rect().size
	return vp / 2.0

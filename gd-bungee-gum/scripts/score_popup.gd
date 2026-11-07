extends RefCounted
## Pickup feedback lives outside the collected item.
const DURATION := 0.65

static func spawn(item: Node2D, points: int) -> Label:
	var popup := Label.new()
	popup.name = "ScorePopup"
	popup.text = str(points)
	popup.theme = preload("res://resources/score_popup_theme.tres")
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.z_index = 10
	var host := item.get_parent()
	if host is TileMapLayer:
		host = host.get_parent()
	host.add_child(popup)
	popup.global_position = item.global_position - Vector2(popup.get_minimum_size().x * 0.5, 32)
	var tween := popup.create_tween().set_parallel()
	tween.tween_property(popup, "position:y", popup.position.y - 32.0, DURATION)
	tween.tween_property(popup, "modulate:a", 0.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(popup.queue_free)
	return popup

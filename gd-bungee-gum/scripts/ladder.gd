@tool
extends Node2D
## Feet-origin, axis-aligned ladder. No solid collision or gum target.
@export_range(32.0, 1024.0, 1.0) var height := 128.0:
	set(value):
		height = value
		if is_node_ready():
			_update_visual()
@export_range(4.0, 64.0, 1.0) var grab_half_width := 18.0

func _ready() -> void:
	add_to_group("ladders")
	_update_visual()

func _update_visual() -> void:
	$Sprite2D.position.y = -height * 0.5
	$Sprite2D.scale = Vector2.ONE * height / 1536.0

func contains_feet(point: Vector2) -> bool:
	return absf(point.x - global_position.x) <= grab_half_width and point.y >= global_position.y - height - 2.0 and point.y <= global_position.y + 2.0

func top_y() -> float:
	return global_position.y - height

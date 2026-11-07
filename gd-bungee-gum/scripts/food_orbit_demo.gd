extends Node2D
## Standalone artwork display: foods orbit while their artwork stays upright.

@export_range(80.0, 320.0, 1.0) var orbit_radius: float = 230.0
@export_range(-180.0, 180.0, 1.0) var orbit_speed_degrees: float = 30.0

var _angle: float = 0.0

@onready var _foods: Node2D = $Foods


func _ready() -> void:
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()


func _process(delta: float) -> void:
	_angle = fposmod(_angle + deg_to_rad(orbit_speed_degrees) * delta, TAU)
	_update_layout()


func _update_layout() -> void:
	position = get_viewport_rect().size * 0.5
	var count: int = _foods.get_child_count()
	for index in range(count):
		var food := _foods.get_child(index) as Sprite2D
		food.position = Vector2.from_angle(_angle + TAU * index / count) * orbit_radius

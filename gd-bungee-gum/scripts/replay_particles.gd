extends Node2D
var circles: Array = []

func _draw() -> void:
	for circle in circles:
		draw_circle(circle[0], circle[1], circle[2], true, -1, true)

extends Node2D
## Draw the recorded ribbon; no connection state or physics is reconstructed.
var data: Dictionary = {}
var glow: Node2D

func _ready() -> void:
	glow = Node2D.new()
	glow.show_behind_parent = true
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = additive
	glow.draw.connect(_draw_glow)
	add_child(glow)

func _draw() -> void:
	glow.queue_redraw()
	if data.is_empty():
		return
	if data.ready:
		draw_dashed_line(data.points[0], data.endpoint, data.color, data.width, data.dash)
		draw_arc(data.endpoint, data.reticle_radius, 0, TAU, 20, data.color, data.reticle_width)
		return
	_shape(self, data.color, data.width, 0.0)
	_shape(self, data.color.lerp(Color(1, 1, 1, data.color.a), data.core), maxf(1, data.width * 0.75), 0, 0.4)

func _draw_glow() -> void:
	if data.is_empty() or data.ready or data.glow_radius <= 0 or data.glow_opacity <= 0:
		return
	for layer in range(24, 0, -1):
		var fraction := float(layer) / 24.0
		var color := Color(data.color, data.color.a * data.glow_opacity * exp(-4.5 * fraction * fraction) / 6)
		_shape(glow, color, data.width, data.glow_radius * fraction)

func _shape(canvas: Node2D, color: Color, width: float, spread: float, marker_scale := 1.0) -> void:
	if data.points.size() > 1:
		canvas.draw_polyline(data.points, color, width + spread * 2, true)
	for point in data.pivots:
		canvas.draw_circle(point, 3 * marker_scale + spread, color, true, -1, true)
	canvas.draw_circle(data.endpoint, 5 * marker_scale + spread, color, true, -1, true)

extends Node2D
## Local screen refraction; each hit keeps its original world-space center.
const Settings = preload("res://scripts/game_settings.gd")
const SHADER = preload("res://shaders/gum_hit_shockwave.gdshader")
const MAX_BURSTS := 4
var settings: Settings
var gum: Node2D
var bursts: Array[Dictionary] = []

func bind(connection: Node2D, tuning: Settings) -> void:
	gum = connection
	settings = tuning
	gum.adhesion_started.connect(_start)

func _start(_normal: Vector2, _is_ring: bool) -> void:
	if not settings.gum_hit_shockwave_enabled or settings.gum_hit_shockwave_duration <= 0.0:
		return
	if bursts.size() >= MAX_BURSTS:
		_remove(0)
	var quad := Polygon2D.new()
	var radius := maxf(1.0, settings.gum_hit_shockwave_radius)
	quad.polygon = PackedVector2Array([Vector2(-radius, -radius), Vector2(radius, -radius), Vector2(radius, radius), Vector2(-radius, radius)])
	quad.uv = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN])
	var material_instance := ShaderMaterial.new()
	material_instance.shader = SHADER
	material_instance.set_shader_parameter("strength", settings.gum_hit_shockwave_strength)
	material_instance.set_shader_parameter("opacity", settings.gum_hit_shockwave_opacity)
	quad.material = material_instance
	add_child(quad)
	quad.top_level = true
	quad.global_position = gum.endpoint()
	bursts.append({"quad": quad, "age": 0.0, "duration": settings.gum_hit_shockwave_duration})

func _process(delta: float) -> void:
	if settings == null:
		return
	if not settings.gum_hit_shockwave_enabled:
		stop()
		return
	for i in range(bursts.size() - 1, -1, -1):
		var burst := bursts[i]
		burst.age += delta
		if burst.age >= burst.duration:
			_remove(i)
		else:
			burst.quad.material.set_shader_parameter("progress", burst.age / burst.duration)

func _remove(index: int) -> void:
	var quad: Polygon2D = bursts[index].quad
	quad.hide()
	quad.queue_free()
	bursts.remove_at(index)

func stop() -> void:
	while not bursts.is_empty():
		_remove(bursts.size() - 1)

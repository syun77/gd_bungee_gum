extends Node2D
## Distance-sampled shot residue. All positions and velocities are world-space.
const Settings = preload("res://scripts/game_settings.gd")
const MAX_PARTICLES := 64
const DRAG := 16.0
var settings: Settings
var particles: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var distance_to_next := 0.0
var halo: Node2D

func _ready() -> void:
	rng.randomize()
	halo = Node2D.new()
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo.material = additive
	halo.draw.connect(_draw_halos)
	add_child(halo)

func bind(gum: Node2D, tuning: Settings) -> void:
	settings = tuning
	gum.shot_started.connect(_begin_shot)
	gum.shot_advanced.connect(_emit_segment)

func _begin_shot() -> void:
	distance_to_next = _spacing()

func _spacing() -> float:
	return maxf(2.0, settings.gum_particle_spacing) * rng.randf_range(0.8, 1.2)

func _emit_segment(start: Vector2, end: Vector2) -> void:
	if not settings.gum_shot_particles_enabled:
		return
	var length := start.distance_to(end)
	if length <= 0.0:
		return
	var direction := (end - start) / length
	var normal := direction.orthogonal()
	while distance_to_next <= length:
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var spread := maxf(0.0, settings.gum_particle_spread)
		if particles.size() >= MAX_PARTICLES:
			particles.pop_front()
		particles.append({
			"position": start + direction * distance_to_next + normal * side * rng.randf_range(minf(2.0, spread), spread),
			"velocity": -direction * rng.randf_range(8.0, 20.0) + normal * side * rng.randf_range(8.0, 24.0),
			"age": 0.0,
			"lifetime": maxf(0.02, settings.gum_particle_lifetime * rng.randf_range(0.7, 1.3)),
			"radius": rng.randf_range(0.5, 1.0) if rng.randf() < 0.9 else 1.5,
			"color": Color("#CE6D9F") if rng.randf() < 0.15 else Color("#FFE1F2"),
		})
		distance_to_next += _spacing()
	distance_to_next -= length
	_redraw()

func _process(delta: float) -> void:
	if settings == null:
		return
	if not settings.gum_shot_particles_enabled:
		if not particles.is_empty():
			stop()
		return
	if particles.is_empty():
		return
	var decay := exp(-DRAG * delta)
	for i in range(particles.size() - 1, -1, -1):
		var particle := particles[i]
		particle.age += delta
		if particle.age >= particle.lifetime:
			particles.remove_at(i)
			continue
		particle.position += particle.velocity * (1.0 - decay) / DRAG
		particle.velocity *= decay
	_redraw()

func stop() -> void:
	particles.clear()
	distance_to_next = 0.0
	_redraw()

func _redraw() -> void:
	queue_redraw()
	if is_instance_valid(halo):
		halo.queue_redraw()

func _appearance(particle: Dictionary) -> Vector2:
	var progress: float = particle.age / particle.lifetime
	return Vector2(lerpf(1.0, 0.25, progress), minf(particle.age / 0.02, 1.0) * pow(1.0 - progress, 1.5) * settings.gum_particle_opacity)

func _draw() -> void:
	for particle in particles:
		var appearance := _appearance(particle)
		draw_circle(to_local(particle.position), particle.radius * appearance.x, Color(particle.color, appearance.y), true, -1.0, true)

func _draw_halos() -> void:
	for particle in particles:
		var appearance := _appearance(particle)
		for layer in range(3, 0, -1):
			halo.draw_circle(halo.to_local(particle.position), (particle.radius + layer) * appearance.x, Color(1.0, 0.45, 0.72, appearance.y * 0.045), true, -1.0, true)

func replay_particles() -> Array:
	var circles: Array = []
	for particle in particles:
		var appearance := _appearance(particle)
		circles.append([particle.position, float(particle.radius * appearance.x), Color(particle.color, appearance.y)])
	return circles

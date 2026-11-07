extends Node2D
## Adhesion bursts remain at their world-space hit position after release.
const Settings = preload("res://scripts/game_settings.gd")
const MAX_BURSTS := 4
const MAX_PARTICLES_PER_BURST := 16
const EXPANSION_TIME := 0.14
const ARC_LIFETIME := 0.11
var settings: Settings
var gum: Node2D
var bursts: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var halo: Node2D

func _ready() -> void:
	rng.randomize()
	halo = Node2D.new()
	halo.show_behind_parent = true
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo.material = additive
	halo.draw.connect(_draw_halos)
	add_child(halo)

func bind(connection: Node2D, tuning: Settings) -> void:
	gum = connection
	settings = tuning
	gum.adhesion_started.connect(_start)

func _start(normal: Vector2, is_ring: bool) -> void:
	if not settings.gum_hit_particles_enabled:
		return
	var center: Vector2 = gum.endpoint()
	var axis := normal.normalized()
	if not is_ring:
		center += axis * 1.5
	var start_angle := 0.0 if is_ring else axis.angle() - PI * 0.5
	var sweep := TAU if is_ring else PI
	var count := clampi(settings.gum_hit_particle_count, 4, MAX_PARTICLES_PER_BURST)
	var particles: Array[Dictionary] = []
	for i in count:
		# Stratified angles retain a readable ring without an evenly spaced pattern.
		var angle := start_angle + sweep * (i + rng.randf_range(0.15, 0.85)) / count
		particles.append({
			"direction": Vector2.from_angle(angle),
			"start_radius": rng.randf_range(3.0, 5.0),
			"end_radius": maxf(6.0, settings.gum_hit_particle_radius) * (rng.randf_range(0.45, 0.65) if i % 5 == 0 else rng.randf_range(0.8, 1.1)),
			"expansion_time": EXPANSION_TIME * rng.randf_range(0.85, 1.1),
			"lifetime": maxf(0.08, settings.gum_hit_particle_lifetime) * rng.randf_range(0.85, 1.0),
			"radius": 1.5 if rng.randf() < 0.1 else rng.randf_range(0.5, 1.0),
			"color": Color("#CE6D9F") if rng.randf() < 0.15 else Color("#FFE1F2"),
		})
	if bursts.size() >= MAX_BURSTS:
		bursts.pop_front()
	bursts.append({"center": center, "age": 0.0, "particles": particles,
		"start_angle": start_angle, "sweep": sweep,
		"arc_radius": maxf(6.0, settings.gum_hit_particle_radius),
		"arcs": settings.gum_hit_arcs_enabled})
	_redraw()

func _process(delta: float) -> void:
	if settings == null:
		return
	if not settings.gum_hit_particles_enabled:
		if not bursts.is_empty():
			stop()
		return
	if bursts.is_empty():
		return
	for i in range(bursts.size() - 1, -1, -1):
		var burst := bursts[i]
		burst.age += delta
		var particles: Array[Dictionary] = burst.particles
		for j in range(particles.size() - 1, -1, -1):
			if burst.age >= particles[j].lifetime:
				particles.remove_at(j)
		if particles.is_empty() and (not burst.arcs or burst.age >= ARC_LIFETIME):
			bursts.remove_at(i)
	_redraw()

func stop() -> void:
	bursts.clear()
	_redraw()

func _redraw() -> void:
	queue_redraw()
	if is_instance_valid(halo):
		halo.queue_redraw()

func _expansion(age: float, duration: float) -> float:
	return 1.0 - pow(1.0 - clampf(age / duration, 0.0, 1.0), 3.0)

func particle_position(burst: Dictionary, particle: Dictionary) -> Vector2:
	return burst.center + particle.direction * lerpf(particle.start_radius, particle.end_radius, _expansion(burst.age, particle.expansion_time))

func _draw() -> void:
	_draw_particles(self, false)
	_draw_arcs()

func _draw_arcs() -> void:
	for burst in bursts:
		if not burst.arcs or not settings.gum_hit_arcs_enabled or burst.age >= ARC_LIFETIME:
			continue
		var radius := lerpf(4.0, burst.arc_radius, _expansion(burst.age, EXPANSION_TIME))
		var alpha: float = 0.28 * (1.0 - burst.age / ARC_LIFETIME) * settings.gum_hit_particle_opacity
		for i in 2:
			var start: float = burst.start_angle + burst.sweep * (0.08 + i * 0.5)
			var end: float = start + minf(deg_to_rad(80.0), burst.sweep * 0.35)
			draw_arc(to_local(burst.center), radius, start, end, 16, Color(1.0, 0.65, 0.85, alpha), 1.0, true)

func _draw_halos() -> void:
	_draw_particles(halo, true)

func _draw_particles(canvas: Node2D, glowing: bool) -> void:
	for burst in bursts:
		for particle in burst.particles:
			var progress: float = burst.age / particle.lifetime
			var scale := lerpf(1.0, 0.25, progress)
			var alpha: float = minf(burst.age / 0.02, 1.0) * (1.0 - progress * progress) * settings.gum_hit_particle_opacity
			var point := canvas.to_local(particle_position(burst, particle))
			if glowing:
				for layer in range(3, 0, -1):
					canvas.draw_circle(point, (particle.radius + layer) * scale, Color(1.0, 0.45, 0.72, alpha * 0.045), true, -1.0, true)
			else:
				canvas.draw_circle(point, particle.radius * scale, Color(particle.color, alpha), true, -1.0, true)

func replay_particles() -> Array:
	var circles: Array = []
	for burst in bursts:
		for particle in burst.particles:
			var progress: float = burst.age / particle.lifetime
			var scale := lerpf(1.0, 0.25, progress)
			var alpha: float = minf(burst.age / 0.02, 1.0) * (1.0 - progress * progress) * settings.gum_hit_particle_opacity
			circles.append([particle_position(burst, particle), float(particle.radius * scale), Color(particle.color, alpha)])
	return circles

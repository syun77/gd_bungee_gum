extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func verify() -> void:
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var gum = game.gum
	var effect = game.get_node("GumShotParticles")
	effect.settings = game.settings.duplicate()
	effect.set_process(false)
	var box = game.get_node("LightBox")
	box.freeze = true
	box.position = Vector2(10000, 200)
	game.player.position = Vector2(9900, 234)
	await physics_frame
	await process_frame
	check(effect.particles.is_empty(), "READY has no particles")
	effect.rng.seed = 1234
	gum.fire(Vector2.RIGHT)
	for i in 30:
		gum.step(1.0 / 60.0, 0.0)
		if gum.connected():
			break
	check(gum.connected(), "Actual shot reaches rigid target")
	check(effect.particles.size() >= 6, "Outbound emits distance-sampled particles")
	for particle in effect.particles:
		check(particle.position.x <= gum.endpoint().x, "No emission beyond hit face")
	check(gum.player_force.is_zero_approx(), "Particle emission preserves force-free arrival")
	var count: int = effect.particles.size()
	gum.step(1.0 / 60.0, 0.0)
	check(effect.particles.size() == count, "Attached contraction emits no particles")
	gum.detach()
	gum.step(1.0 / 60.0, 0.0)
	check(effect.particles.size() == count, "Detach and return retain residue without emission")
	var residue: Vector2 = effect.particles[0].position
	game.player.position += Vector2(100, 100)
	effect._process(0.01)
	check(effect.particles[0].position.distance_to(residue) < 1.0, "Residue stays in world space")
	gum.fire(Vector2.LEFT)
	check(effect.particles.size() == count, "Refire preserves old residue")
	effect._process(effect.settings.gum_particle_lifetime * 1.3 + 0.01)
	check(effect.particles.is_empty(), "All residue expires")
	effect.stop()
	gum.detach()
	gum.cancel_return()
	game.player.position = Vector2(9900, 534)
	gum.fire(Vector2.RIGHT)
	gum.step(1.0, 0.0)
	check(gum.state == gum.State.RETURNING and not effect.particles.is_empty(), "Large-step miss leaves outbound residue")
	count = effect.particles.size()
	gum.step(0.01, 0.0)
	check(effect.particles.size() == count, "Miss return emits no additional particles")
	effect.stop()
	gum.cancel_return()
	gum.fire(Vector2.UP)
	gum.detach()
	gum.step(0.01, 0.0)
	check(effect.particles.is_empty(), "Canceled shot before travel emits nothing")
	# Sampling must be independent of segment partitioning, including eight-way aim.
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(), Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()]:
		effect.stop()
		effect.rng.seed = 5678
		effect._begin_shot()
		effect._emit_segment(Vector2.ZERO, direction * 160.0)
		var positions: Array[Vector2] = []
		for particle in effect.particles:
			positions.append(particle.position)
		check(positions.size() >= 13 and positions.size() <= 20, "160px density remains sparse")
		effect.stop()
		effect.rng.seed = 5678
		effect._begin_shot()
		for i in 8:
			effect._emit_segment(direction * i * 20.0, direction * (i + 1) * 20.0)
		check(effect.particles.size() == positions.size(), "Segment partition preserves density")
		for i in mini(positions.size(), effect.particles.size()):
			check(positions[i].is_equal_approx(effect.particles[i].position), "Segment partition preserves positions")
	effect._emit_segment(Vector2.ZERO, Vector2(10000, 0))
	check(effect.particles.size() == 64, "Particle pool is bounded")
	effect.settings.gum_shot_particles_enabled = false
	effect._process(0.01)
	effect._emit_segment(Vector2.ZERO, Vector2(160, 0))
	check(effect.particles.is_empty(), "Disable clears and suppresses particles")
	effect.settings.gum_shot_particles_enabled = true
	effect._begin_shot()
	effect._emit_segment(Vector2.ZERO, Vector2(160, 0))
	effect.stop()
	check(effect.particles.is_empty(), "Restart cleanup clears residue")
	game.queue_free()
	await process_frame
	print("Gum shot particles: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)

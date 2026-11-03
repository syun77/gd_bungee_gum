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
	var effect = game.get_node("GumHitParticles")
	effect.settings = game.settings.duplicate()
	effect.set_process(false)
	effect.rng.seed = 6123
	var box = game.get_node("LightBox")
	box.freeze = true
	box.position = Vector2(10000, 200)
	game.player.position = Vector2(9900, 234)
	await physics_frame
	await process_frame
	check(effect.bursts.is_empty(), "READY has no hit particles")
	gum.fire(Vector2.RIGHT)
	check(effect.bursts.is_empty(), "Firing does not emit hit particles")
	for i in 30:
		gum.step(1.0 / 60.0, 0.0)
		if gum.connected():
			break
	check(gum.connected() and effect.bursts.size() == 1, "Actual shot arrival emits one burst")
	check(gum.player_force.is_zero_approx(), "Hit particles preserve force-free arrival")
	check(effect.z_index == gum.z_index and effect.get_index() > gum.get_index() and effect.z_index < game.get_node("GumAttachmentEffect").z_index, "Hit particles draw above gum and below patch")
	var burst: Dictionary = effect.bursts[0]
	check(burst.particles.size() == 12 and not burst.arcs, "Default sparse particle ring has no arcs")
	for particle in burst.particles:
		check(particle.direction.dot(Vector2.LEFT) >= -0.0001, "Surface burst stays in outward hemisphere")
		check(effect.particle_position(burst, particle).distance_to(burst.center) >= 2.99, "Particles begin around center, not in patch")
	var center: Vector2 = burst.center
	box.position += Vector2(30, 20)
	box.rotation = 0.4
	game.player.position += Vector2(10, 10)
	effect._process(0.14)
	check(burst.center.is_equal_approx(center), "Burst center is world-space despite target movement")
	var expanded: Vector2 = effect.particle_position(burst, burst.particles[1])
	check(expanded.distance_to(center) > 12.0, "Ring expands outward by 0.14s")
	gum.contract()
	gum.step(1.0 / 60.0, 0.0)
	check(effect.bursts.size() == 1, "Contraction does not retrigger burst")
	gum.detach()
	check(effect.bursts.size() == 1, "Detach retains residue")
	effect._process(0.13)
	check(effect.bursts.is_empty(), "Burst expires by configured lifetime")
	box.position = Vector2(10000, 200)
	box.rotation = 0.0
	# All surface orientations use the supplied physics normal.
	for normal in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-1, -1).normalized()]:
		effect.stop()
		gum._attach_hit({"collider": box, "rid": box.get_rid(), "position": box.position, "normal": normal})
		burst = effect.bursts[0]
		check(burst.center.is_equal_approx(box.position + normal * 1.5), "Surface center offsets outward")
		for particle in burst.particles:
			check(particle.direction.dot(normal) >= -0.0001, "Floor/wall/ceiling/rotated face hemisphere")
		gum.detach()
	# Real tile adhesion resolves the centered full-circle burst.
	var anchors := TileMapLayer.new()
	anchors.tile_set = game.get_node("TheaterStage/GumAnchors").tile_set
	anchors.physics_quadrant_size = 1
	anchors.position = Vector2(10000, -200)
	anchors.set_cell(Vector2i.ZERO, 2, Vector2i.ZERO)
	game.add_child(anchors)
	center = anchors.to_global(anchors.map_to_local(Vector2i.ZERO))
	game.player.position = center + Vector2(-100, 34)
	await physics_frame
	await process_frame
	effect.stop()
	effect.settings.gum_hit_arcs_enabled = true
	check(gum.attach_at(center + Vector2(0, 10)), "Actual ring adhesion succeeds")
	burst = effect.bursts[0]
	check(burst.center.is_equal_approx(center) and is_equal_approx(burst.sweep, TAU), "Ring burst is centered and full-circle")
	check(burst.arcs, "Optional arcs enabled for new burst")
	var quadrants := [false, false, false, false]
	for particle in burst.particles:
		var angle: float = fposmod(particle.direction.angle(), TAU)
		quadrants[int(angle / (PI / 2.0))] = true
	check(not quadrants.has(false), "Ring particles cover all four quadrants")
	anchors.erase_cell(Vector2i.ZERO)
	await physics_frame
	await process_frame
	gum.validate_connection()
	check(effect.bursts.size() == 1, "Target deletion retains independent residue")
	effect._process(0.12)
	check(not effect.bursts.is_empty() and burst.age > effect.ARC_LIFETIME, "Arcs finish before particle residue")
	effect._process(0.15)
	check(effect.bursts.is_empty(), "Erased-target burst expires without querying target")
	# Repeat adhesion is bounded and prior residues remain independent.
	for i in 6:
		gum._attach_hit({"collider": box, "rid": box.get_rid(), "position": box.position, "normal": Vector2.LEFT})
		gum.detach()
	check(effect.bursts.size() == 4, "Repeated hits retain only four bursts")
	var total := 0
	for item in effect.bursts:
		total += item.particles.size()
	check(total <= 64, "Particle count remains bounded")
	effect.settings.gum_hit_particles_enabled = false
	effect._process(0.01)
	gum._attach_hit({"collider": box, "rid": box.get_rid(), "position": box.position, "normal": Vector2.LEFT})
	check(effect.bursts.is_empty(), "Disable clears residue and suppresses new bursts")
	gum.detach()
	effect.settings.gum_hit_particles_enabled = true
	gum._attach_hit({"collider": box, "rid": box.get_rid(), "position": box.position, "normal": Vector2.LEFT})
	effect.stop()
	check(effect.bursts.is_empty(), "Restart cleanup clears immediately")
	gum.detach()
	gum.cancel_return()
	game.player.position = Vector2(9900, 534)
	gum.fire(Vector2.RIGHT)
	gum.step(1.0, 0.0)
	check(gum.state == gum.State.RETURNING and effect.bursts.is_empty(), "Miss never emits hit particles")
	game.queue_free()
	await process_frame
	print("Gum hit particles: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)

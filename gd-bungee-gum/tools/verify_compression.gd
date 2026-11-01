extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("verify")
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1
func rectangle(world: Node, point: Vector2, size: Vector2, rigid := false) -> PhysicsBody2D:
	var body: PhysicsBody2D = RigidBody2D.new() if rigid else StaticBody2D.new()
	body.position = point
	body.collision_layer = 4 if rigid else 1
	body.collision_mask = 7
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	world.add_child(body)
	return body
func verify() -> void:
	if "--two-block-only" in OS.get_cmdline_user_args():
		await verify_two_blocks()
		await verify_two_blocks(true)
		await verify_contact_impact()
		quit(1 if failures else 0)
		return
	for entry in [[1.0, 1.0, false, false, false], [-1.0, 6.0, true, false, false], [1.0, 1.0, true, true, false], [1.0, 1.0, false, false, true]]:
		await verify_case(entry[0], entry[1], entry[2], entry[3], entry[4])
	await verify_two_blocks()
	await verify_two_blocks(true)
	await verify_contact_impact()
	if failures == 0:
		print("PASS: mirrored dynamic pressure, rotating gum pull, existing overlap, mass, floor/gravity and kick escape")
	quit(1 if failures else 0)

func verify_case(side: float, mass: float, rotating: bool, use_gum: bool, precompressed: bool) -> void:
	var world := Node2D.new()
	root.add_child(world)
	rectangle(world, Vector2(0, 600), Vector2(128, 200))
	rectangle(world, Vector2(side * 240, 660), Vector2(480, 40))
	var player = load("res://scenes/characters/player.tscn").instantiate()
	world.add_child(player)
	player.settings = player.settings.duplicate()
	player.settings.jump_diagnostics = false
	player.settings.landing_diagnostics = false
	player.settings.pinning_diagnostics = false
	player.position = Vector2(side * (68.41 if precompressed else 74.1), 639.9)
	var box := rectangle(world, Vector2(side * (96.446 if precompressed else (220.0 if use_gum else 120.0)), 620), Vector2(40, 40), true) as RigidBody2D
	box.mass = mass
	box.lock_rotation = not rotating
	box.angular_velocity = -side * 2.0 if rotating else 0.0
	var gum = load("res://scripts/gum_connection.gd").new()
	gum.player = player
	gum.settings = player.settings
	gum.settings.gum_diagnostics = false
	world.add_child(gum)
	player.gum = gum
	await physics_frame
	await process_frame
	if use_gum:
		check(gum.attach_at(box.position), "Real gum attaches pressure fixture")
	var inward := "move_left" if side > 0.0 else "move_right"
	Input.action_press(inward)
	var minimum_x := 1000.0
	var gum_pull_ticks := 0
	for tick in 150:
		await physics_frame
		if use_gum:
			gum.step(1.0 / 60.0)
			if gum.tension > 0.0:
				gum_pull_ticks += 1
		else:
			box.apply_central_force(Vector2(-side * 3000, 0))
		player.simulate(1.0 / 60.0)
		minimum_x = minf(minimum_x, side * player.position.x)
		await process_frame
	if use_gum:
		check(gum_pull_ticks > 0 and gum.connected(), "Gum must physically pull and retain attachment through compression")
		check(absf(box.position.x - player.position.x) < 80.0, "Gum must bring block into the wall-side contact region")
	Input.action_release(inward)
	gum.detach()
	print("compression min_x=", minimum_x, " feet=", player.position, " box=", box.position, " ext=", player.external_velocity, " floor=", player.is_on_floor(), " normal=", player.get_floor_normal())
	check(minimum_x >= 73.5, "Compression must not push player deeply into terrain")
	for tick in 60:
		await physics_frame
		player.simulate(1.0 / 60.0)
		await process_frame
	check(player.is_on_floor() and absf(player.external_velocity.y) < 50, "Release must retain floor and bounded gravity")
	print("before kick feet=", player.position, " ext=", player.external_velocity, " floor=", player.is_on_floor(), " kick=", player.kick_available)
	var y: float = player.position.y
	await physics_frame
	player.simulate(1.0 / 60.0, true)
	await process_frame
	for tick in 12:
		await physics_frame
		player.simulate(1.0 / 60.0)
		await process_frame
	print("after kick feet=", player.position, " ext=", player.external_velocity)
	check(player.position.y < y - 20, "Contact kick must escape after pressure stops")
	world.free()

func verify_two_blocks(pressure := false) -> void:
	var world := Node2D.new()
	root.add_child(world)
	rectangle(world, Vector2(480, 660), Vector2(800, 40))
	var player = load("res://scenes/characters/player.tscn").instantiate()
	world.add_child(player)
	player.settings = player.settings.duplicate()
	player.settings.jump_diagnostics = false
	player.settings.landing_diagnostics = false
	player.settings.pinning_diagnostics = false
	player.position = Vector2(483.9097, 639.9238)
	var left := rectangle(world, Vector2(458.8684, 620.3), Vector2(40, 40), true) as RigidBody2D
	var right := rectangle(world, Vector2(500.0003, 620.3), Vector2(40, 40), true) as RigidBody2D
	left.mass = 1.0
	right.mass = 6.0
	left.lock_rotation = true
	right.lock_rotation = true
	# Register the overlapping shapes without giving the capsule a teleport velocity.
	left.freeze = true
	right.freeze = true
	for tick in 2:
		await physics_frame
		await process_frame
	left.freeze = false
	right.freeze = false
	left.sleeping = true
	right.sleeping = true
	player._repel_rigid_contacts(1.0 / 60.0, Vector2.ZERO)
	check(player.rigid_contact_normals.size() == 2, "Sleeping dynamic pair must produce independent contact constraints")
	var left_velocity: Vector2 = PhysicsServer2D.body_get_state(left.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY)
	var right_velocity: Vector2 = PhysicsServer2D.body_get_state(right.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY)
	check(left_velocity.x < 0.0 and right_velocity.x > 0.0, "Both sleeping blocks must receive outward impulses")
	check(absf(left_velocity.x * left.mass + right_velocity.x * right.mass + player.external_velocity.x * player.settings.player_mass) < 0.01, "Pair response must transfer equal/opposite momentum before contact cleanup")
	for tick in 90:
		await physics_frame
		if pressure:
			left.apply_central_force(Vector2(3000, 0))
			right.apply_central_force(Vector2(-3000, 0))
		player.simulate(1.0 / 60.0)
		await process_frame
	if pressure:
		var loaded_gap := right.position.x - left.position.x - 40.0
		print("two-block loaded_gap=", loaded_gap)
		check(loaded_gap > 20.1, "Sustained opposing block pressure must not deeply crush capsule")
		for tick in 60:
			await physics_frame
			player.simulate(1.0 / 60.0)
			await process_frame
	var gap := right.position.x - left.position.x - 40.0
	print("two-block gap=", gap, " feet=", player.position, " ext=", player.external_velocity)
	check(gap > 19.5 and gap < 300.0, "Two dynamic blocks must open a capsule-width gap")
	check(player.is_on_floor() and absf(player.external_velocity.y) < 50.0, "Two-block compression must recover floor without accumulated gravity")
	var y: float = player.position.y
	await physics_frame
	player.simulate(1.0 / 60.0, true)
	await process_frame
	for tick in 12:
		await physics_frame
		player.simulate(1.0 / 60.0)
		await process_frame
	check(player.position.y < y - 20.0, "Kick must escape two dynamic blocks")
	world.free()

func verify_contact_impact() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var player = load("res://scenes/characters/player.tscn").instantiate()
	world.add_child(player)
	player.settings = player.settings.duplicate()
	player.settings.pinning_diagnostics = false
	player.position = Vector2.ZERO
	var box := rectangle(world, Vector2(29.5, -4), Vector2(40, 40), true) as RigidBody2D
	box.gravity_scale = 0.0
	box.center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	box.center_of_mass = Vector2(0, 8)
	box.freeze = true
	for tick in 2:
		await physics_frame
		await process_frame
	box.freeze = false
	await physics_frame
	await process_frame
	box.position = Vector2(29.5, -4)
	box.rotation = 0.0
	PhysicsServer2D.body_set_state(box.get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
	PhysicsServer2D.body_set_state(box.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2(-120, 0))
	player._repel_rigid_contacts(1.0 / 60.0, Vector2.ZERO)
	var after: Vector2 = PhysicsServer2D.body_get_state(box.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY)
	check(absf(PhysicsServer2D.body_get_state(box.get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY)) > 0.001, "Off-center collision impulse must produce rigid angular response")
	check(after.x > -120.0 and player.external_velocity.x < 0.0, "A single incoming block must receive an immediate collision impulse")
	check(absf(box.mass * after.x + player.settings.player_mass * player.external_velocity.x + box.mass * 120.0) < 0.01, "Single contact preserves total linear momentum")
	PhysicsServer2D.body_set_state(box.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2(500, 0))
	player.external_velocity = Vector2.ZERO
	player._repel_rigid_contacts(1.0 / 60.0, Vector2.ZERO)
	after = PhysicsServer2D.body_get_state(box.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY)
	check(after.is_equal_approx(Vector2(500, 0)), "Already separating block must not receive another repulsion impulse")
	world.free()

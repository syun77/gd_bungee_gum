extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func ticks(count: int) -> void:
	for index in count:
		await physics_frame
		await process_frame

# Physical events exercise InputMap, unlike action_press which bypasses key bindings.
func verify_movement_keys() -> void:
	for key in [KEY_A, KEY_LEFT, KEY_D, KEY_RIGHT, KEY_PAGEUP]:
		var event := InputEventKey.new()
		event.physical_keycode = key
		event.pressed = true
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		var expected := -1.0 if key in [KEY_A, KEY_LEFT] else (0.0 if key == KEY_PAGEUP else 1.0)
		assert(Input.get_axis("move_left", "move_right") == expected,
			"Unexpected movement for physical key: " + OS.get_keycode_string(key))
		var release := InputEventKey.new()
		release.physical_keycode = key
		release.pressed = false
		Input.parse_input_event(release)
		Input.flush_buffered_events()
		assert(Input.get_axis("move_left", "move_right") == 0.0)

func verify() -> void:
	verify_movement_keys()
	var game: Node2D = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	var player = game.get_node("Player")
	assert(player.settings == game.settings and game.get_node("Gum").settings == game.settings,
		"Game, player and gum must share the assigned tuning resource")
	var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
	await ticks(40)
	assert(player.is_on_floor(), "Player must land on stage")
	assert(sprite.animation == &"idle")
	assert(absf(player.position.y - 640.0) < 1.0, "Feet must align with floor")
	var start_x: float = player.position.x
	var original_speed: float = game.settings.run_speed
	game.settings.run_speed = 110.0
	Input.action_press("move_right")
	await ticks(12)
	assert(is_equal_approx(player.control_velocity.x, 110.0), "Movement must read the settings resource")
	game.settings.run_speed = original_speed
	assert(player.position.x > start_x + 10.0)
	assert(sprite.animation == &"run")
	Input.action_release("move_right")
	Input.action_press("jump")
	await ticks(2)
	assert(not player.is_on_floor())
	assert(player.velocity.y < 0.0)
	assert(sprite.animation == &"jump")
	Input.action_release("jump")
	await ticks(3)
	var rising_speed: float = player.velocity.y
	Input.action_press("jump")
	await ticks(2)
	assert(player.velocity.y > rising_speed, "Air input must not add a second impulse")
	Input.action_release("jump")
	await ticks(55)
	assert(player.is_on_floor())
	assert(sprite.animation == &"idle")
	# Real floor contact must dissipate momentum gradually in either direction.
	for speed in [300.0, -300.0]:
		player.position = Vector2(240, 640)
		player.external_velocity = Vector2(speed, 0)
		await ticks(1)
		assert(absf(player.external_velocity.x) < absf(speed))
		assert(absf(player.external_velocity.x) > 200.0, "Landing must not erase momentum instantly")
		await ticks(30)
		assert(absf(player.external_velocity.x) < 0.1, "Floor friction must stop external sliding")
	# In flight, release momentum survives until actual landing.
	player.position = Vector2(240, 480)
	player.external_velocity = Vector2(120, -100)
	await ticks(2)
	assert(not player.is_on_floor())
	var airborne_speed: float = player.external_velocity.x
	await ticks(8)
	assert(is_equal_approx(player.external_velocity.x, airborne_speed), "Air must retain horizontal momentum")
	await ticks(65)
	assert(player.is_on_floor())
	assert(absf(player.external_velocity.x) < 0.1, "Landing must start friction")
	player.external_velocity = Vector2(-200.0, 0.0)
	player.position = Vector2(80, 640)
	await ticks(25)
	assert(player.position.x >= 73.0)
	assert(absf(player.external_velocity.x) < 0.1, "Wall must clear inward external momentum")
	await verify_pinning_diagnostics(game)
	await verify_floor_kick_direction(game)
	await verify_coyote_time(game)
	await verify_coyote_gravity_compensation(game)
	await verify_wall_landing_jump(game)
	await verify_corner_retention(game)
	await verify_corner_landing(game)
	print("PASS: physical A/D/arrow bindings and PageUp exclusion, spawn, floor alignment, idle/run/jump/landing, no air jump, wall momentum cleanup, ground friction and retained air momentum")
	quit()

func verify_corner_landing(game: Node2D) -> void:
	game.set_physics_process(false)
	var player = game.get_node("Player")
	# Recovery floor below the step's right side isolates landing from the stage pit.
	var recovery := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(400, 40)
	collider.shape = shape
	recovery.position = Vector2(1000, 660)
	recovery.add_child(collider)
	game.add_child(recovery)
	await physics_frame
	for direction in [1.0, -1.0]:
		# Step at x576 (rightward), mirrored contact at x800 (leftward).
		player.position = Vector2(520 if direction > 0 else 856, 550)
		player.control_velocity = Vector2(220 * direction, 0)
		player.external_velocity = Vector2(700 * direction, 0)
		player.velocity = player.control_velocity + player.external_velocity
		var action := "move_right" if direction > 0 else "move_left"
		Input.action_press(action)
		var grounded_ticks := 0
		for tick in 180:
			await physics_frame
			if tick == 8:
				Input.action_release(action)
			player.simulate(1.0 / 60.0)
			assert(player.control_velocity.y == 0.0, "Corner collision must not retain vertical input velocity")
			if tick >= 150 and player.is_on_floor():
				grounded_ticks += 1
		assert(grounded_ticks == 30, "High-speed corner traversal must settle without repeated lift-off")
		assert(player.sprite.animation == &"idle" and player.landing_time == 0.0)
	recovery.queue_free()
	print("PASS: high-speed corner landing in both directions, horizontal intent and stable grounded idle")

func verify_wall_landing_jump(game: Node2D) -> void:
	game.set_physics_process(false)
	var player = game.get_node("Player")
	player.position = Vector2(74, 640)
	player.control_velocity = Vector2.ZERO
	player.external_velocity = Vector2.ZERO
	Input.action_press("move_left")
	for tick in 8:
		await physics_frame
		player.simulate(1.0 / 60.0)
	assert(player.is_on_floor() and player.is_on_wall())
	for attempt in 3:
		await physics_frame
		player.simulate(1.0 / 60.0, true)
		assert(not player.is_on_floor() and player.external_velocity.y < -100.0,
			"Each floor jump must work after landing against a wall")
		assert(player.is_on_wall(), "Reproduction must retain wall contact at takeoff")
		var landed := false
		for tick in 120:
			await physics_frame
			player.simulate(1.0 / 60.0)
			assert(player.is_on_floor() or player.is_on_wall() or player.is_on_ceiling(),
				"Reproduction must never have a fully non-contact tick")
			if player.is_on_floor():
				landed = true
				break
		assert(landed, "Wall jump must land before next attempt")
	Input.action_release("move_left")
	print("PASS: three floor jumps with continuous wall contact through landing")

func verify_coyote_time(game: Node2D) -> void:
	game.set_physics_process(false)
	var player = game.get_node("Player")
	var platform := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(96, 40)
	collider.shape = shape
	platform.position = Vector2(10000, 660)
	platform.add_child(collider)
	game.add_child(platform)
	var original_grace: float = game.settings.coyote_time
	for scenario in ["within", "expired", "disabled", "consumed"]:
		game.settings.coyote_time = 0.0 if scenario == "disabled" else 0.1
		player.position = Vector2(10000, 630)
		player.control_velocity = Vector2.ZERO
		player.external_velocity = Vector2.ZERO
		for tick in 12:
			await physics_frame
			player.simulate(1.0 / 60.0)
		assert(player.is_on_floor(), "Coyote fixture must start on real floor")
		if scenario == "consumed":
			await physics_frame
			player.simulate(1.0 / 60.0, true)
			assert(not player.is_on_floor())
		else:
			Input.action_press("move_right")
			for tick in 60:
				await physics_frame
				player.simulate(1.0 / 60.0)
				if not player.is_on_floor():
					break
			Input.action_release("move_right")
			assert(not player.is_on_floor(), "Must walk off platform")
		for tick in (10 if scenario == "expired" else 2):
			await physics_frame
			player.simulate(1.0 / 60.0)
		var before: Vector2 = player.external_velocity
		var gravity_budget: Vector2 = player.coyote_gravity_velocity + Vector2(0, game.settings.gravity / 60.0)
		await physics_frame
		player.simulate(1.0 / 60.0, true)
		var expected := before + Vector2(0, game.settings.gravity / 60.0)
		if scenario == "within":
			var normal := Vector2.UP
			var correction := minf(maxf(-expected.dot(normal), 0.0), maxf(-gravity_budget.dot(normal), 0.0))
			expected += Vector2.UP * (game.settings.kick_speed + correction)
		assert(player.external_velocity.is_equal_approx(expected), "Coyote impulse eligibility: " + scenario)
		assert(player.coyote_remaining == 0.0, "Grace must be consumed or expired")
		# Repeated airborne requests cannot use the same grace twice.
		before = player.external_velocity
		await physics_frame
		player.simulate(1.0 / 60.0, true)
		assert(player.external_velocity.is_equal_approx(before + Vector2(0, game.settings.gravity / 60.0)))
	game.settings.coyote_time = original_grace
	platform.queue_free()
	print("PASS: real walk-off coyote kick, expiry, disabled grace, consumed floor kick and no repeated air impulse")

func verify_coyote_gravity_compensation(game: Node2D) -> void:
	var player = game.get_node("Player")
	var original_grace: float = game.settings.coyote_time
	var original_diagnostics: bool = game.settings.jump_diagnostics
	game.settings.jump_diagnostics = false
	game.settings.coyote_time = 0.2
	for horizontal_speed in [-140.0, 0.0, 140.0]:
		for dt in [1.0 / 60.0, 1.0 / 120.0]:
			for delay in [2, 6, 10]:
				for vertical_speed in [0.0, 500.0, -30.0, -300.0]:
					# Isolate airborne momentum after departure; the platform test covers real contact.
					player.position = Vector2(12000, 0)
					player.external_velocity = Vector2.ZERO
					player.control_velocity = Vector2.ZERO
					await physics_frame
					player.simulate(dt)
					assert(not player.is_on_floor() and not player.is_on_wall())
					player.coyote_remaining = 0.2
					player.coyote_gravity_velocity = Vector2.ZERO
					var initial := Vector2(horizontal_speed, vertical_speed)
					player.external_velocity = initial
					for tick in delay:
						await physics_frame
						player.simulate(dt)
					await physics_frame
					player.simulate(dt, true)
					var gravity_change := Vector2(0, game.settings.gravity * dt * (delay + 1))
					var expected: Vector2 = initial + gravity_change
					var inward := maxf(expected.y, 0.0)
					var correction := minf(inward, gravity_change.y)
					expected += Vector2.UP * (game.settings.kick_speed + correction)
					assert(player.external_velocity.distance_to(expected) < 0.01,
						"Compensate gravity only; preserve tangent/outward/excess falling momentum")
					assert(is_equal_approx(player.external_velocity.x, horizontal_speed), "Kick and compensation must preserve horizontal momentum")
					if vertical_speed == 0.0:
						assert(absf(-player.external_velocity.y - game.settings.kick_speed) < 0.01,
							"Pure-gravity launch speed must not depend on grace timing")
					assert(player.coyote_gravity_velocity == Vector2.ZERO)
	game.settings.coyote_time = original_grace
	game.settings.jump_diagnostics = original_diagnostics
	print("PASS: coyote gravity compensation across timings, timesteps and horizontal/upward/excess downward momentum")

func verify_floor_kick_direction(game: Node2D) -> void:
	game.set_physics_process(false)
	var player = game.get_node("Player")
	var platform := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(96, 40)
	collider.shape = shape
	platform.add_child(collider)
	platform.position = Vector2(14000, 660)
	game.add_child(platform)
	for side in [-1.0, 1.0]:
		for coyote in [false, true]:
			player.position = Vector2(14000 + side * 51, 630)
			player.external_velocity = Vector2.ZERO
			player.control_velocity = Vector2.ZERO
			for tick in 12:
				await physics_frame
				player.simulate(1.0 / 60.0)
			assert(player.is_on_floor(), "Corner fixture must be grounded")
			assert(absf(player.get_floor_normal().x) > 0.1, "Must exercise a tilted capsule corner normal")
			if coyote:
				player.position += Vector2(side * 30, -5)
				for tick in 3:
					await physics_frame
					player.simulate(1.0 / 60.0)
				assert(not player.is_on_floor() and player.coyote_remaining > 0.0)
			var before: Vector2 = player.external_velocity
			await physics_frame
			player.simulate(1.0 / 60.0, true)
			assert(absf(player.external_velocity.x - before.x) < 0.01, "Corner floor/coyote kick must add no horizontal velocity")
			assert(player.external_velocity.y < -300.0 and not player.is_on_floor())
	platform.queue_free()
	print("PASS: left/right tilted corner floor and delayed coyote launches add no horizontal velocity")

func verify_pinning_diagnostics(game: Node2D) -> void:
	game.set_physics_process(false)
	var player = game.get_node("Player")
	var fixture := Node2D.new()
	game.add_child(fixture)
	for entry in [[Vector2(10000, 660), Vector2(200, 40), false],
		[Vector2(9969, 600), Vector2(40, 120), false],
		[Vector2(10030, 620), Vector2(40, 40), true]]:
		var body: PhysicsBody2D = RigidBody2D.new() if entry[2] else StaticBody2D.new()
		body.position = entry[0]
		body.name = "PinningBlock" if entry[2] else "PinningTerrain%d" % fixture.get_child_count()
		body.collision_layer = 4 if entry[2] else 1
		if body is RigidBody2D:
			body.freeze = true
		var collider := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = entry[1]
		collider.shape = shape
		body.add_child(collider)
		fixture.add_child(body)
	player.position = Vector2(10000, 639.9)
	player.external_velocity = Vector2.ZERO
	player.control_velocity = Vector2.ZERO
	var enabled: bool = game.settings.pinning_diagnostics
	game.settings.pinning_diagnostics = true
	Input.action_press("move_right")
	for tick in 12:
		await physics_frame
		player.simulate(1.0 / 60.0)
	assert(player.pinning_diagnostic_active, "Rigid contact must activate pinning diagnostics")
	assert(player.pinning_diagnostic_history.size() == 8, "Pinning history must stay bounded")
	var snapshot: Dictionary = player.pinning_diagnostic_history[-1]
	assert(snapshot.move_axis == 1.0 and snapshot.incoming.x > 0.0, "Log must retain attempted motion before collision cleanup")
	assert(absf(snapshot.displacement.x) < 0.1, "Fixture must reproduce blocked movement")
	assert(player.is_on_floor(), "Blocked-animation fixture must remain grounded")
	assert(player.sprite.animation == &"run", "Grounded movement input must keep run animation when a block prevents displacement")
	var nearby: Array = player._pinning_nearby_bodies()
	assert(nearby.size() >= 2, "Nearby query must expose wall and rigid block even if slide contacts omit wall")
	game.settings.pinning_diagnostics = false
	await physics_frame
	player.simulate(1.0 / 60.0)
	assert(not player.pinning_diagnostic_active and player.pinning_diagnostic_history.is_empty(), "Disabled diagnostic clears capture")
	Input.action_release("move_right")
	game.settings.pinning_diagnostics = enabled
	fixture.free()
	print("PASS: pinning contact capture, blocked input/displacement, bounded history, nearby bodies and disable toggle")

func verify_corner_retention(game: Node2D) -> void:
	game.set_physics_process(false)
	var player = game.get_node("Player")
	var platform := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(96, 40)
	collider.shape = shape
	platform.add_child(collider)
	platform.position = Vector2(16000, 660)
	game.add_child(platform)
	for side in [-1.0, 1.0]:
		for offset in [0.0, 3.0, 5.0, 7.0, 9.0, 9.8, 9.99]:
			for fall_speed in [0.0, 300.0, 600.0]:
				var start_x: float = 16000 + side * (48 + offset)
				player.position = Vector2(start_x, 600)
				player.control_velocity = Vector2.ZERO
				player.external_velocity = Vector2(0, fall_speed)
				var landed := false
				for tick in 90:
					await physics_frame
					player.simulate(1.0 / 60.0)
					if player.is_on_floor():
						landed = true
					if landed:
						assert(player.is_on_floor(), "Corner must retain original support")
						assert(absf(player.position.x - start_x) < 0.1, "Vertical landing drift: side=%s offset=%s fall=%s tick=%s pos=%s start=%s normal=%s" % [side, offset, fall_speed, tick, player.position, start_x, player.get_floor_normal()])
						assert(player.external_velocity.length() < 0.1, "Corner support must absorb downward momentum")
				assert(landed)
	# A diagonal descent at the very corner must not turn falling speed into pushback.
	var configured_angle: float = player.floor_max_angle
	for side in [-1.0, 1.0]:
		player.position = Vector2(16000 + side * 57.5, 646)
		player.control_velocity = Vector2(-side * 58.33333, 0)
		player.external_velocity = Vector2(0, 278.3334)
		for tick in 8:
			var before: Vector2 = player.position
			await physics_frame
			player.simulate(1.0 / 60.0)
			assert(absf(player.external_velocity.x) < 0.1, "Descending corner contact must not create sideways pushback")
			assert((player.position.x - before.x) * side < 0.1, "Engine corner movement must not push away from ledge")
			assert(player.floor_max_angle == configured_angle, "Support exception must not change configured slope limit")
	# Actual side and underside contact remain walls/ceilings, not floor support.
	player.position = Vector2(16000 - 59, 670)
	player.control_velocity = Vector2(200, 0)
	player.external_velocity = Vector2(0, 100)
	for tick in 3:
		await physics_frame
		player.simulate(1.0 / 60.0)
	assert(player.is_on_wall() and not player.is_on_floor(), "Side fixture: pos=%s floor=%s wall=%s angle=%s contacts=%s" % [player.position, player.is_on_floor(), player.is_on_wall(), player.floor_max_angle, player._slide_contacts()])
	assert(absf(player.external_velocity.x) < 0.1 and player.external_velocity.y > 100)
	player.position = Vector2(16000, 740)
	player.control_velocity = Vector2.ZERO
	player.external_velocity = Vector2(0, -400)
	for tick in 4:
		await physics_frame
		player.simulate(1.0 / 60.0)
	assert(not player.is_on_floor() and player.external_velocity.y >= 0)
	# Restore extreme-corner support for load and departure checks.
	player.position = Vector2(16000 + 57.8, 600)
	player.external_velocity = Vector2.ZERO
	for tick in 40:
		await physics_frame
		player.simulate(1.0 / 60.0)
	assert(player.is_on_floor())
	# Same actual corner support: downward gum-like load stays supported, upward pull departs.
	player.apply_external_force(Vector2(0, 1200), 1.0 / 60.0)
	await physics_frame
	player.simulate(1.0 / 60.0)
	assert(player.is_on_floor() and absf(player.external_velocity.x) < 0.1)
	player.external_velocity = Vector2(0, -200)
	await physics_frame
	player.simulate(1.0 / 60.0)
	assert(not player.is_on_floor() and player.external_velocity.y < -100)
	# Horizontal momentum is retained and is allowed to leave the ledge.
	player.position = Vector2(16000 + 51, 630)
	player.external_velocity = Vector2.ZERO
	for tick in 20:
		await physics_frame
		player.simulate(1.0 / 60.0)
	assert(player.is_on_floor())
	player.external_velocity = Vector2(200, 0)
	await physics_frame
	player.simulate(1.0 / 60.0)
	assert(player.external_velocity.x > 150, "Support must retain existing horizontal momentum")
	for tick in 20:
		await physics_frame
		player.simulate(1.0 / 60.0)
	assert(not player.is_on_floor(), "Momentum must still allow walking/sliding off a ledge")
	# Face lookup respects rotation, shape index and unsupported side normals.
	for angle in [0.3, PI / 2]:
		platform.rotation = angle
		var local_point := Vector2(0, -20) if angle < 1 else Vector2(-48, 0)
		var expected := Vector2(sin(angle), -cos(angle)) if angle < 1 else Vector2.UP
		var contact := {"body": platform, "shape": 0, "point": platform.to_global(local_point), "normal": Vector2.UP}
		assert(player._support_face_normal(contact).distance_to(expected) < 0.001)
		contact.normal = Vector2.RIGHT
		assert(player._support_face_normal(contact) == Vector2.RIGHT)
	platform.queue_free()
	print("PASS: mirrored original-corner retention, offsets 0/3/5/7/9/9.8/9.99 and falling speeds 0/300/600")

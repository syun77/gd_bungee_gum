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
	print("PASS: physical A/D/arrow bindings and PageUp exclusion, spawn, floor alignment, idle/run/jump/landing, no air jump, wall momentum cleanup, ground friction and retained air momentum")
	quit()

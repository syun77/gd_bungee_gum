extends SceneTree
var failures := 0
var game: Node2D
var player: CharacterBody2D
var gum: Node2D

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		failures += 1

func ticks(count: int) -> void:
	for index in count:
		await physics_frame
		await process_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func fixture() -> void:
	for code in [KEY_X, KEY_Z, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		key(code, false)
	if is_instance_valid(game):
		game.free()
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	player = game.player
	gum = game.gum
	game.settings = game.settings.duplicate()
	game.settings.maximum_length = 900.0
	game.settings.attachment_range = 900.0
	game.settings.gum_shot_speed = 2400.0
	game.settings.jump_diagnostics = false
	player.settings = game.settings
	gum.settings = game.settings
	await ticks(40)

func pad_button(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func pad_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func verify_pad() -> void:
	await fixture()
	pad_axis(JOY_AXIS_LEFT_X, 0.15)
	await ticks(1)
	check(is_zero_approx(Input.get_axis("move_left", "move_right")), "Stick drift below deadzone is ignored")
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		pad_axis(JOY_AXIS_LEFT_X, direction.x * 0.8)
		pad_axis(JOY_AXIS_LEFT_Y, direction.y * 0.6)
		await ticks(1)
		check(game.aim_direction.is_equal_approx(direction.normalized()), "Stick eight-way aim " + str(direction))
	pad_axis(JOY_AXIS_LEFT_X, 0.0)
	pad_axis(JOY_AXIS_LEFT_Y, 0.0)
	for button in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]:
		pad_button(button, true)
		await ticks(1)
		var expected: Vector2 = {JOY_BUTTON_DPAD_LEFT: Vector2.LEFT, JOY_BUTTON_DPAD_RIGHT: Vector2.RIGHT, JOY_BUTTON_DPAD_UP: Vector2.UP, JOY_BUTTON_DPAD_DOWN: Vector2.DOWN}[button]
		check(game.aim_direction.is_equal_approx(expected), "D-pad direction " + str(button))
		if button in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
			check(Input.is_action_pressed("move_left" if button == JOY_BUTTON_DPAD_LEFT else "move_right"), "D-pad also moves")
		pad_button(button, false)
		await ticks(1)
	pad_button(JOY_BUTTON_DPAD_UP, true)
	pad_button(JOY_BUTTON_X, true)
	await ticks(30)
	check(gum.connected(), "Square fires and attaches through live Game")
	check(gum.mode == gum.Mode.CONTRACT, "Arrival auto-contracts")
	pad_button(JOY_BUTTON_X, false)
	pad_button(JOY_BUTTON_DPAD_UP, false)
	await ticks(1)
	pad_button(JOY_BUTTON_DPAD_DOWN, true)
	await ticks(2)
	check(gum.mode == gum.Mode.LOOSEN, "D-pad Down relaxes")
	pad_button(JOY_BUTTON_DPAD_DOWN, false)
	pad_button(JOY_BUTTON_X, true)
	await ticks(1)
	check(gum.mode == gum.Mode.CONTRACT, "New Square press contracts")
	pad_button(JOY_BUTTON_A, true)
	await ticks(1)
	check(not gum.connected() and player.external_velocity.y < 0.0, "Cross releases and jumps upward")
	await ticks(20)
	check(not gum.connected(), "Held Square never refires after Cross")
	for button in [JOY_BUTTON_A, JOY_BUTTON_X]:
		pad_button(button, false)
	pad_button(JOY_BUTTON_START, true)
	check(Input.is_action_just_pressed("restart"), "OPTIONS maps to restart")
	pad_button(JOY_BUTTON_START, false)
	game.set_physics_process(false)
	await ticks(1)

func verify_attached_jump() -> void:
	for rising_speed in [600.0, 0.0, -250.0]:
		for relaxed in [false, true]:
			await fixture()
			player.position = Vector2(160, 400)
			player.external_velocity = Vector2.ZERO
			await ticks(1)
			check(gum.attach_at(Vector2(160, 100)), "Release-jump fixture attaches")
			if relaxed:
				gum.relax()
			player.air_jump_available = true
			player.kick_available = false
			player.coyote_remaining = 0.0
			player.external_velocity = Vector2(75, rising_speed)
			key(KEY_Z, true)
			await ticks(1)
			var expected_y: float = minf(rising_speed + game.settings.gravity / 60.0, 0.0) - game.settings.kick_speed
			check(not gum.connected(), "Attached Z releases before jumping")
			check(absf(player.external_velocity.y - expected_y) < 0.1, "Release jump cancels descent or adds to ascent: " + str(rising_speed))
			check(absf(player.external_velocity.x - 75.0) < 0.1, "Release jump retains horizontal momentum")
			await ticks(2)
			check(player.external_velocity.y > expected_y, "Held Z cannot repeat release jump")
			key(KEY_Z, false)
			await ticks(1)
			key(KEY_Z, true)
			await ticks(1)
			check(is_equal_approx(player.external_velocity.y, -game.settings.double_jump_kick_speed), "Detached airborne fresh Z assigns double-jump speed")
			key(KEY_Z, false)

func verify() -> void:
	await verify_attached_jump()
	await verify_pad()
	await fixture()
	check(gum.aim_valid, "Neutral guide still predicts a target")
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		key(KEY_LEFT, direction.x < 0)
		key(KEY_RIGHT, direction.x > 0)
		key(KEY_UP, direction.y < 0)
		key(KEY_DOWN, direction.y > 0)
		await ticks(1)
		check(game.aim_direction.is_equal_approx(direction.normalized()), "Continuous physical eight-way direction: " + str(direction))
	key(KEY_LEFT, true)
	key(KEY_RIGHT, true)
	key(KEY_UP, true)
	key(KEY_DOWN, true)
	await ticks(1)
	check(game.aim_direction.is_equal_approx(Vector2(1, 1).normalized()), "Opposing keys cancel and preserve direction")
	for code in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		key(code, false)
	await ticks(1)
	check(game.aim_direction.is_equal_approx(Vector2(1, 1).normalized()), "Neutral retains direction with subdued guide")
	var start: Vector2 = player.position
	key(KEY_RIGHT, true)
	key(KEY_UP, true)
	key(KEY_X, true)
	await ticks(1)
	check(gum.state == gum.State.OUTBOUND and gum.shot_direction.is_equal_approx(Vector2(1, -1).normalized()), "Same-tick arrows and X press immediately fire diagonally")
	await ticks(2)
	check(player.position.x > start.x, "Direction preview and held X never suppress running")
	var distance: float = gum.shot_distance
	key(KEY_X, false)
	await ticks(1)
	check(gum.shot_distance > distance, "X release does not restart flight")
	key(KEY_X, true)
	await ticks(1)
	check(gum.shot_distance > distance, "Outbound X cannot replace moving tip")

	await fixture()
	key(KEY_UP, true)
	key(KEY_X, true)
	await ticks(1)
	check(gum.state == gum.State.OUTBOUND, "Upward shot starts on press before release")
	await ticks(20)
	check(gum.connected() and gum.mode == gum.Mode.CONTRACT and game.up_wait_release, "Arrival auto-contracts and gates held pre-attachment Up")
	gum.relax()
	var length: float = gum.rest_length
	await ticks(2)
	check(gum.rest_length == length, "Pre-attachment Up cannot manually shorten")
	key(KEY_UP, false)
	await ticks(1)
	key(KEY_UP, true)
	await ticks(2)
	check(gum.rest_length < length and gum.mode == gum.Mode.LOOSEN, "Fresh Up shortens after release")
	key(KEY_UP, false)
	key(KEY_DOWN, true)
	await ticks(2)
	check(gum.mode == gum.Mode.LOOSEN, "Fresh Down relaxes and extends")
	length = gum.rest_length
	await ticks(2)
	check(gum.rest_length > length, "Down continuously extends")
	key(KEY_UP, true)
	await ticks(1)
	length = gum.rest_length
	await ticks(2)
	check(gum.rest_length == length, "Opposing manual keys hold natural length")
	key(KEY_X, false)
	await ticks(1)
	key(KEY_X, true)
	await ticks(1)
	check(gum.mode == gum.Mode.LOOSEN, "Down wins over attached X")
	key(KEY_DOWN, false)
	await ticks(1)
	check(gum.mode == gum.Mode.LOOSEN, "Held X does not retrigger after Down release")
	key(KEY_X, false)
	await ticks(1)
	key(KEY_X, true)
	await ticks(1)
	check(gum.mode == gum.Mode.CONTRACT, "Fresh attached X resumes contraction over Up")
	key(KEY_X, false)
	key(KEY_UP, false)
	await ticks(1)
	var momentum: Vector2 = player.external_velocity
	game._handle_actions(true)
	check(not gum.connected() and gum.state == gum.State.RETURNING and player.external_velocity == momentum, "Z immediately detaches into nonphysical return")
	key(KEY_X, true)
	await ticks(1)
	check(gum.state == gum.State.OUTBOUND and gum.return_points.is_empty(), "New X cancels return and fires in the same tick")
	key(KEY_Z, true)
	await ticks(1)
	check(not gum.connected() and gum.state != gum.State.OUTBOUND, "Z cancels flight")
	key(KEY_Z, false)
	await ticks(30)
	check(gum.state == gum.State.READY, "Held X cannot repeat after return completes")
	key(KEY_X, false)
	await ticks(1)
	check(gum.state == gum.State.READY, "X release never fires")

	await fixture()
	key(KEY_X, true)
	key(KEY_DOWN, true)
	await ticks(2)
	check(gum.connected() and gum.mode == gum.Mode.CONTRACT and game.down_wait_release, "Pre-shot Down is gated at nearby floor arrival")
	key(KEY_DOWN, false)
	await ticks(1)
	key(KEY_DOWN, true)
	await ticks(1)
	check(gum.mode == gum.Mode.LOOSEN, "Down requires release and fresh press after arrival")
	key(KEY_Z, true)
	await ticks(1)
	check(not gum.connected() and player.velocity.y < 0.0, "Ground Z detaches before contact kick")

	await fixture()
	key(KEY_X, true)
	key(KEY_UP, true)
	await ticks(1)
	key(KEY_UP, false)
	key(KEY_DOWN, true)
	await ticks(20)
	check(gum.connected() and gum.mode == gum.Mode.CONTRACT and game.down_wait_release, "Down first pressed during flight is also gated at attachment")
	key(KEY_X, false)
	await ticks(1)
	key(KEY_Z, true)
	key(KEY_X, true)
	await ticks(1)
	check(not gum.connected() and gum.state != gum.State.OUTBOUND, "Simultaneous Z/X gives Z priority")
	key(KEY_Z, false)
	await ticks(30)
	check(gum.state == gum.State.READY, "Simultaneous Z/X cannot fire later while held")
	key(KEY_X, false)
	await ticks(1)
	gum.attach_at(Vector2(160, 100))
	key(KEY_X, true)
	await ticks(1)
	gum.detach("TARGET LOST")
	await ticks(30)
	check(gum.state == gum.State.READY, "Attached X cannot repeat on connection loss")
	for code in [KEY_X, KEY_Z, KEY_UP, KEY_DOWN]:
		key(code, false)
	game.free()
	if failures == 0:
		print("PASS: press fire, constant eight-way preview, neutral/opposing direction, movement, release/no-repeat, pre-attachment Up/Down gates, length controls, Z priority, return interrupt/refire")
	quit(1 if failures else 0)

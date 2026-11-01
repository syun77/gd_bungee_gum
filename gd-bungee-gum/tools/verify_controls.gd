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

func verify() -> void:
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

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

func verify() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	player = game.get_node("Player")
	gum = game.get_node("Gum")
	await ticks(40)
	check(not InputMap.has_action("kick_off") and not InputMap.has_action("gum_attach") and not InputMap.has_action("gum_contract") and not InputMap.has_action("gum_detach"), "Obsolete control actions removed")
	var start := player.position
	key(KEY_X, true)
	key(KEY_UP, true)
	key(KEY_RIGHT, true)
	await ticks(2)
	check(game.gesture == game.Gesture.AIM and not gum.connected(), "X hold only aims")
	check(game.aim_direction.is_equal_approx(Vector2(1, -1).normalized()), "Diagonal aim normalized")
	check(absf(player.position.x - start.x) < 0.1, "Aim arrows must not steer player")
	key(KEY_LEFT, true)
	await ticks(1)
	check(game.aim_direction == Vector2.UP, "Opposing horizontal keys cancel")
	key(KEY_LEFT, false)
	key(KEY_RIGHT, false)
	await ticks(1)
	key(KEY_UP, false)
	await ticks(1)
	check(game.aim_direction == Vector2.UP, "No direction retains last aim")
	# Exercise all eight physical arrow combinations before returning to upward aim.
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		key(KEY_LEFT, direction.x < 0)
		key(KEY_RIGHT, direction.x > 0)
		key(KEY_UP, direction.y < 0)
		key(KEY_DOWN, direction.y > 0)
		await ticks(1)
		check(game.aim_direction.is_equal_approx(direction.normalized()), "Physical eight-way direction: " + str(direction))
	key(KEY_LEFT, false)
	key(KEY_RIGHT, false)
	key(KEY_DOWN, false)
	key(KEY_UP, true)
	await ticks(1)
	key(KEY_UP, false)
	key(KEY_X, false)
	await ticks(2)
	check(gum.connected() and gum.mode == gum.Mode.CONTRACT, "X release shoots and starts auto-contract")
	var length: float = gum.rest_length
	await ticks(3)
	check(gum.rest_length < length, "Auto-contract needs no held key")
	key(KEY_X, true)
	await ticks(2)
	check(gum.mode == gum.Mode.LOOSEN, "Attached X enters loosen mode")
	length = gum.rest_length
	check(length >= gum.origin().distance_to(gum.endpoint()), "Loosen creates real slack")
	await ticks(8)
	check(gum.mode == gum.Mode.LOOSEN and gum.rest_length == length, "Holding X neither repeats toggle nor pays out length")
	key(KEY_X, false)
	await ticks(2)
	check(gum.mode == gum.Mode.LOOSEN, "Toggle gesture release does not fire")
	key(KEY_X, true)
	await ticks(2)
	check(gum.mode == gum.Mode.CONTRACT, "Next X resumes auto-contract")
	key(KEY_X, false)
	await ticks(70)
	check(not player.is_on_floor(), "Auto-contract lifts player")
	# Call the gesture handler without a physics step to isolate detach from gravity.
	var momentum: Vector2 = player.external_velocity
	game._handle_gesture(true)
	check(not gum.connected() and player.external_velocity == momentum, "Air Z detaches without injecting impulse")
	await ticks(1)
	check(player.external_velocity.y >= momentum.y, "Airborne release gains no upward jump boost")
	# Cancel an aim gesture with Z and consume its eventual X release.
	key(KEY_X, true)
	await ticks(1)
	key(KEY_Z, true)
	await ticks(1)
	check(game.gesture == game.Gesture.WAIT_RELEASE, "Z cancels held aim")
	key(KEY_Z, false)
	key(KEY_X, false)
	await ticks(2)
	check(not gum.connected() and game.gesture == game.Gesture.IDLE, "Canceled aim cannot fire on release")
	# Make a new stationary scene for simultaneous keys and ground jump.
	game.free()
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	player = game.get_node("Player")
	gum = game.get_node("Gum")
	await ticks(40)
	gum.attach_at(Vector2(160, 100))
	key(KEY_X, true)
	key(KEY_Z, true)
	await ticks(2)
	check(not gum.connected() and player.velocity.y < 0.0, "Ground Z detaches then kicks; wins over X")
	key(KEY_Z, false)
	key(KEY_X, false)
	await ticks(2)
	check(not gum.connected(), "Simultaneous Z/X does not fire on release")
	# An attached gesture remains a toggle even if target is lost before release.
	gum.attach_at(Vector2(160, 100))
	key(KEY_X, true)
	await ticks(2)
	gum.detach("TARGET LOST")
	await ticks(1)
	key(KEY_X, false)
	await ticks(2)
	check(not gum.connected(), "Broken connection during held toggle cannot release-fire")
	# Miss and short-tap both return to idle; no implicit repeat shot.
	game.aim_direction = Vector2.DOWN
	player.position = Vector2(900, -2000)
	key(KEY_X, true)
	await ticks(1)
	key(KEY_X, false)
	await ticks(2)
	check(not gum.connected() and game.gesture == game.Gesture.IDLE, "Miss consumes short-tap gesture")
	await ticks(3)
	check(not gum.connected(), "Miss does not repeat")
	game.free()
	if failures == 0:
		print("PASS: physical Z/X, 8-way aim/retention/opposing keys, aim movement suppression, release fire, auto-contract, explicit loosen toggle/hold, Z air momentum/ground impulse/priority, cancel/break release safety, miss/no-repeat")
	quit(1 if failures else 0)

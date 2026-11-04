extends SceneTree
var failures := 0
var events: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func tick(player: CharacterBody2D) -> void:
	await physics_frame
	player.simulate(1.0 / 60.0)
	await process_frame

func drop(player: CharacterBody2D, speed: Vector2, x := 10000.0) -> void:
	player.position = Vector2(x, 336)
	player.external_velocity = speed
	player.control_velocity = Vector2.ZERO
	for i in 100:
		await tick(player)
		if player.is_on_floor():
			break

func verify() -> void:
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game._physics_process(game.entrance.TOTAL_TIME)
	game.set_physics_process(false)
	var player = game.player
	player.settings = player.settings.duplicate()
	player.settings.jump_diagnostics = false
	player.settings.landing_diagnostics = false
	player.settings.pinning_diagnostics = false
	var effect = game.get_node("LandingDustEffect")
	effect.set_process(false)
	effect.settings = player.settings
	player.landed.connect(func(point, normal, speed, body): events.append({"point": point, "normal": normal, "speed": speed, "body": body}))
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000, 32)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(10000, 416)
	game.add_child(floor_body)
	await drop(player, Vector2.ZERO)
	check(events.is_empty() and not effect.visible, "Initial spawn settling has no dust")
	await drop(player, Vector2.ZERO)
	check(events.size() == 1 and effect.visible and effect.texture == effect.NORMAL, "Real normal landing emits and plays normal dust")
	check(absf(effect.global_position.y - 400.0) < 1.0 and absf(effect.global_rotation) < 0.01, "Dust pivot follows actual floor contact")
	var start: Vector2 = effect.global_position
	player.position.x += 50
	effect._process(0.1)
	check(effect.frame == 3 and effect.global_position == start, "30fps dust stays at landing point when player moves")
	effect._process(0.2)
	check(not effect.visible, "Dust ends at 0.30s")
	for i in 20:
		await tick(player)
	check(events.size() == 1, "Standing does not retrigger")
	player.landing_air_time = 0.01
	player.landing_air_distance = 1.0
	player._update_landing_event(1.0 / 60.0, false, player.position, Vector2(0, 500), false)
	check(events.size() == 1, "Brief contact flicker suppressed")
	player.landing_air_time = 0.1
	player.landing_air_distance = 10.0
	player._update_landing_event(1.0 / 60.0, false, player.position, Vector2(0, 500), true)
	check(events.size() == 1, "Compression recovery does not emit dust")
	await drop(player, Vector2(0, 500))
	check(events.size() == 2 and effect.texture == effect.HEAVY and effect.visible, "Fast real fall selects heavy dust")
	await drop(player, Vector2(650, 0))
	check(events.size() == 3 and effect.texture == effect.NORMAL, "Fast horizontal movement does not select heavy dust")
	effect.stop()
	effect._start(Vector2.ZERO, Vector2.UP, 79, null)
	check(not effect.visible, "Gentle impacts suppressed")
	var box := RigidBody2D.new()
	box.freeze = true
	box.position = Vector2(12000, 416)
	box.rotation = 0.12
	var box_shape := CollisionShape2D.new()
	box_shape.shape = rect.duplicate()
	box.add_child(box_shape)
	game.add_child(box)
	await drop(player, Vector2.ZERO, 12000.0)
	check(events.size() == 4 and events.back().body == box and effect.surface == box, "Real rotated rigid landing binds contact surface")
	check(absf(effect.global_rotation - box.rotation) < 0.01, "Real rigid landing uses supporting face normal")
	box.rotation = 0.0
	effect._start(box.position + Vector2(0, -20), Vector2.UP, 450, box)
	box.position += Vector2(10, 5)
	box.rotation = 0.3
	effect._process(0.05)
	check(effect.global_position.is_equal_approx(box.to_global(Vector2(0, -20))) and is_equal_approx(effect.global_rotation, 0.3), "Dust follows rigid contact translation/rotation")
	box.queue_free()
	await process_frame
	effect._process(0.01)
	check(not effect.visible, "Deleted supporting body clears dust")
	effect._start(Vector2.ZERO, Vector2.UP, 100, null)
	effect.stop()
	check(not effect.visible, "Restart cleanup clears dust")
	game.queue_free()
	await process_frame
	print("Landing dust: ", "PASS" if failures == 0 else "FAIL", " (", failures, ")")
	quit(0 if failures == 0 else 1)

extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("verify")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func ticks(count := 3) -> void:
	for tick in count:
		await physics_frame
		await process_frame
func verify() -> void:
	for path in ["res://scenes/game.tscn", "res://scenes/game_stage_2.tscn", "res://scenes/game_stage_3.tscn"]:
		var game = load(path).instantiate()
		root.add_child(game)
		game.set_physics_process(false)
		game._physics_process(game.entrance.TOTAL_TIME)
		var door = game.exit_door
		var player = game.player
		var box = game.get_node("LightBox")
		box.global_position = door.global_position - Vector2(0, 20)
		await ticks()
		check(not door.started, "Rigid prop does not trigger exit")
		box.global_position += Vector2(100, 0)
		player.global_position = door.global_position + Vector2(36, 0)
		await ticks()
		check(not door.started and not game.cleared, "Nearby non-contact player does not clear")
		player.global_position = door.global_position + Vector2(25, 0)
		await ticks()
		check(door.active and not game.cleared, "Actual capsule/Area contact starts sequence: " + path)
		check(door.frame == 0 and player.sprite.visible and player.sprite.self_modulate == Color.WHITE, "Start closed, actor normal")
		check(door.settling and player.sprite.animation == &"jump", "Exit first waits for floor contact")
		game._physics_process(1.0 / 60.0)
		check(not door.settling and player.sprite.animation == &"run" and player.sprite.flip_h, "Grounded contact starts run toward center from right")
		var approach_start: Vector2 = player.global_position
		for action in ["move_right", "jump", "gum_action"]:
			Input.action_press(action)
		player.external_velocity = Vector2(300, -200)
		game._physics_process(0.1)
		check(player.global_position.x < approach_start.x and player.global_position.x > door.global_position.x, "Approach moves progressively without teleport")
		check(player.sprite.animation == &"run" and door.frame == 0 and door.elapsed == 0.0, "Run while approaching, door timeline waits")
		check(player.external_velocity == Vector2.ZERO and not game.gum.connected(), "Opposing input/jump/gum cannot interrupt approach")
		for tick in 120:
			if not door.approaching:
				break
			game._physics_process(1.0 / 60.0)
		check(not door.approaching and player.global_position.distance_to(door.global_position) <= 0.5, "Reaches actual door center")
		check(player.sprite.animation == &"exit_back" and not player.sprite.is_playing() and not player.sprite.flip_h, "Switches to static rear pose at center")
		check(player.sprite.sprite_frames.get_frame_texture(&"exit_back", 0).resource_path == "res://assets/characters/teto_back_exit.png", "Uses approved rear artwork")
		var fixed_position: Vector2 = player.position
		game._physics_process(0.2)
		check(door.frame > 0 and player.sprite.self_modulate == Color.WHITE, "Open before darkening")
		game._physics_process(0.2)
		check(door.frame == 5 and player.sprite.visible and player.sprite.animation == &"exit_back", "Rear pose remains fully open before fade")
		game._physics_process(0.25)
		check(door.frame == 5 and is_equal_approx(player.sprite.self_modulate.r, 0.5) and player.sprite.self_modulate.a == 1.0, "Vertex RGB darkens while alpha stays opaque")
		check(player.position == fixed_position and player.external_velocity == Vector2.ZERO, "Movement and momentum reset during exit")
		check(not game.gum.visible and not game.gum.connected(), "No gum input during exit")
		game._physics_process(0.25)
		check(not player.sprite.visible and not player.visible and player.collision_layer == 0 and player.collision_mask == 0 and door.frame == 5 and not game.cleared, "Hide actor before closing")
		game._physics_process(0.2)
		check(door.frame < 5 and door.frame > 0 and not game.cleared, "Closing keeps result hidden")
		game._physics_process(0.21)
		check(not door.active and door.frame == 0 and game.cleared, "Result only after fully closed")
		var panels: int = game.get_node("HUD").get_child_count()
		game._physics_process(0.2)
		check(game.get_node("HUD").get_child_count() == panels, "Result only shown once")
		for action in ["move_right", "jump", "gum_action"]:
			Input.action_release(action)
		game.free()
		await process_frame
	# Real Game ticks and SceneTree pause must freeze an active exit timeline.
	var game = load("res://scenes/game_stage_2.tscn").instantiate()
	root.add_child(game)
	game._physics_process(game.entrance.TOTAL_TIME)
	game.player.global_position = game.exit_door.global_position + Vector2(-25, -8)
	await ticks()
	check(game.exit_door.active, "Live Game contact begins exit")
	check(game.exit_door.settling and game.player.sprite.animation == &"jump", "Airborne contact waits in air pose")
	check(is_equal_approx(game.player.global_position.x, game.exit_door.global_position.x - 25.0), "No horizontal approach before landing")
	game.pause_menu.open()
	var elapsed: float = game.exit_door.elapsed
	var paused_position: Vector2 = game.player.global_position
	await create_timer(0.08, true).timeout
	check(game.exit_door.elapsed == elapsed and game.player.global_position == paused_position and not game.cleared, "Pause freezes exit before clear")
	game.pause_menu.close()
	for tick in 120:
		if game.exit_door.elapsed > elapsed:
			break
		await ticks(1)
	check(not game.exit_door.approaching and game.player.global_position.distance_to(game.exit_door.global_position) <= 0.5, "Live airborne approach aligns at floor/door center")
	check(game.exit_door.elapsed > elapsed, "Cancel resumes exit")
	game.free()
	await process_frame
	# An upward-moving entry retains its vertical arc, with no horizontal motion until landing.
	var airborne_game = load("res://scenes/game_stage_2.tscn").instantiate()
	root.add_child(airborne_game)
	airborne_game.set_physics_process(false)
	airborne_game._physics_process(airborne_game.entrance.TOTAL_TIME)
	var airborne_player = airborne_game.player
	var airborne_door = airborne_game.exit_door
	airborne_player.global_position = airborne_door.global_position + Vector2(-25, -40)
	airborne_player.velocity = Vector2(200, -160)
	airborne_game._begin_exit()
	var entry: Vector2 = airborne_player.global_position
	Input.action_press("move_right")
	Input.action_press("jump")
	Input.action_press("gum_action")
	airborne_game._physics_process(1.0 / 60.0)
	check(airborne_player.global_position.y < entry.y and airborne_player.global_position.x == entry.x, "Vertical entry momentum retained without horizontal drift")
	var landed := false
	for tick in 120:
		if not airborne_door.settling:
			landed = true
			break
		airborne_game._physics_process(1.0 / 60.0)
		check(airborne_player.global_position.x == entry.x and airborne_door.elapsed == 0.0, "Landing wait suppresses input and door timeline")
	check(landed and absf(airborne_player.global_position.y - airborne_door.global_position.y) < 0.5, "Gravity lands on actual floor before run")
	check(airborne_player.sprite.animation == &"run" and not airborne_player.sprite.flip_h, "Landing switches to run facing center")
	check(not airborne_game.gum.connected() and not airborne_game.gum.visible, "Landing wait blocks gum")
	for action in ["move_right", "jump", "gum_action"]:
		Input.action_release(action)
	airborne_game.free()
	await process_frame
	print("Stage exit: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

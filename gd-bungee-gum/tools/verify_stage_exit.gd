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
		var fixed_position: Vector2 = player.position
		for action in ["move_right", "jump", "gum_action"]:
			Input.action_press(action)
		player.external_velocity = Vector2(300, -200)
		game._physics_process(0.2)
		check(door.frame > 0 and player.sprite.self_modulate == Color.WHITE, "Open before darkening")
		game._physics_process(0.2)
		check(door.frame == 5 and player.sprite.visible, "Fully open before fade")
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
	game.player.global_position = game.exit_door.global_position
	await ticks()
	check(game.exit_door.active, "Live Game contact begins exit")
	game.pause_menu.open()
	var elapsed: float = game.exit_door.elapsed
	await create_timer(0.08, true).timeout
	check(game.exit_door.elapsed == elapsed and not game.cleared, "Pause freezes exit before clear")
	game.pause_menu.close()
	await ticks(6)
	check(game.exit_door.elapsed > elapsed, "Cancel resumes exit")
	game.free()
	await process_frame
	print("Stage exit: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

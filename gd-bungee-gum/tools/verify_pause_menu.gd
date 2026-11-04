extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("verify")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func frames(count := 3) -> void:
	for i in count:
		await process_frame
func options(pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_START
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func verify() -> void:
	change_scene_to_file("res://scenes/game.tscn")
	await frames()
	var game = current_scene
	var menu = game.pause_menu
	options(true)
	options(false)
	check(paused and menu.is_open, "Actual OPTIONS opens and pauses")
	check(not game.restarting, "OPTIONS does not restart")
	check(menu.buttons.size() == 3, "Exactly three actions")
	check(menu.buttons[0].has_focus(), "Retry focused for pad")
	var elapsed: float = game.entrance.elapsed
	var position: Vector2 = game.player.position
	var box_position: Vector2 = game.get_node("LightBox").position
	await create_timer(0.15, true).timeout
	check(game.entrance.elapsed == elapsed and game.player.position == position, "Entrance/player frozen while paused")
	check(game.get_node("LightBox").position == box_position, "Rigid physics paused")
	for i in 2:
		var down := InputEventJoypadButton.new()
		down.button_index = JOY_BUTTON_DPAD_DOWN
		down.pressed = true
		Input.parse_input_event(down)
		Input.flush_buffered_events()
		down = InputEventJoypadButton.new()
		down.button_index = JOY_BUTTON_DPAD_DOWN
		down.pressed = false
		Input.parse_input_event(down)
		Input.flush_buffered_events()
		await frames()
	check(menu.buttons[2].has_focus(), "D-pad selects cancel")
	for pressed in [true, false]:
		var cross := InputEventJoypadButton.new()
		cross.button_index = JOY_BUTTON_A
		cross.pressed = pressed
		Input.parse_input_event(cross)
		Input.flush_buffered_events()
		await frames()

	await frames()
	check(not paused and not menu.is_open, "Cancel resumes")
	await create_timer(0.05).timeout
	check(game.entrance.elapsed > elapsed, "Entrance resumes")
	game.entrance.step(game.entrance.TOTAL_TIME)
	game.gum.show()
	game.player.external_velocity = Vector2(100, -50)
	game.get_node("HUD/Menu").pressed.emit()
	await frames()
	check(game.player.external_velocity == Vector2(100, -50), "Pause retains momentum")
	options(true)
	options(false)
	check(not paused, "Second OPTIONS cancels")
	# Resume consumes a UI confirmation without turning it into a gameplay jump/shot.
	Input.action_press("jump")
	var before: Vector2 = game.player.external_velocity
	game._physics_process(1.0 / 60.0)
	check(game.player.external_velocity == before, "Closing frame cannot jump")
	Input.action_release("jump")
	game.pause_menu.open()
	game.pause_menu.buttons[0].pressed.emit()
	await frames()
	check(not paused and current_scene != game, "Retry reloads and unpauses")
	game = current_scene
	check(game.scene_file_path == "res://scenes/game.tscn" and game.entrance.active, "Retry starts entrance")
	game.pause_menu.open()
	game.pause_menu.buttons[1].pressed.emit()
	await frames()
	check(not paused and current_scene.scene_file_path == "res://scenes/stage_select.tscn", "Selection action exits and unpauses")
	print("Pause menu: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func settle() -> void:
	await process_frame
	await process_frame

func verify() -> void:
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/stage_select.tscn", "F5 opens stage selection")
	change_scene_to_file("res://scenes/stage_select.tscn")
	await settle()
	var menu = current_scene
	check(menu.start_button.has_focus(), "Start is focused for keyboard and pad")
	set_meta(&"checkpoint_respawn", {"scene": "stale"})
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	Input.parse_input_event(accept)
	Input.flush_buffered_events()
	await settle()
	accept = InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = false
	Input.parse_input_event(accept)
	Input.flush_buffered_events()
	await settle()
	check(current_scene.scene_file_path == "res://scenes/game.tscn", "Focused accept enters actual game")
	check(not has_meta(&"checkpoint_respawn"), "Selection clears old checkpoint")
	if current_scene.scene_file_path != "res://scenes/game.tscn":
		quit(1)
		return
	var spawn: Vector2 = current_scene.get_node("TheaterStage/PlacementMarkers/PlayerSpawn").global_position
	check(current_scene.player.global_position.distance_to(spawn) <= 24.0, "Stage starts at entrance")
	current_scene.restart()
	await settle()
	check(current_scene.scene_file_path == "res://scenes/game.tscn", "R reloads gameplay rather than menu")
	var cancel := InputEventKey.new()
	cancel.physical_keycode = KEY_ESCAPE
	cancel.keycode = KEY_ESCAPE
	cancel.pressed = true
	Input.parse_input_event(cancel)
	Input.flush_buffered_events()
	await settle()
	check(current_scene.pause_menu.is_open, "Esc opens menu")
	current_scene.pause_menu.buttons[1].pressed.emit()
	await settle()
	check(current_scene.scene_file_path == "res://scenes/stage_select.tscn", "Menu returns to selection")
	current_scene.start_button.pressed.emit()
	await settle()
	current_scene.get_node("HUD/Menu").pressed.emit()
	check(current_scene.pause_menu.is_open, "HUD opens menu")
	current_scene.pause_menu.buttons[1].pressed.emit()
	await settle()
	check(current_scene.scene_file_path == "res://scenes/stage_select.tscn", "HUD button returns to selection")
	for index in [1, 2]:
		var scene_path: String = current_scene.Catalog.STAGES[index].scene
		check(current_scene.stage_buttons.size() == 3, "Three playable stage cards")
		current_scene.stage_buttons[index].pressed.emit()
		await settle()
		check(current_scene.scene_file_path == scene_path, "Card loads distinct gameplay scene")
		check(current_scene.stage_width == 2048 and current_scene.camera.limit_right == 2048, "Compact course camera limits")
		var stage = current_scene.get_node("TheaterStage")
		check(stage.get_node("TerrainTiles").get_used_cells().size() > 100, "Authored terrain loaded")
		check(stage.get_node("GumAnchors").get_used_cells().size() == 9, "Physical rings loaded")
		check(stage.get_node("Foods").get_used_cells().size() == 8, "Stage food placements")
		while current_scene.entrance.active:
			await physics_frame
		for tick in range(10):
			await physics_frame
		check(current_scene.player.is_on_floor(), "Spawn settles on real floor")
		current_scene.player.global_position = Vector2(336, 704)
		current_scene.gum.fire(Vector2.UP)
		for tick in range(15):
			await physics_frame
		check(current_scene.gum.connected(), "Actual shot attaches to reachable course ring")
		current_scene.gum.detach()
		var checkpoint = stage.get_node("Checkpoints/Checkpoint01")
		current_scene._on_checkpoint_reached(checkpoint)
		current_scene.restart(true)
		await settle()
		check(current_scene.scene_file_path == scene_path, "Death restart preserves selected stage")
		check(not current_scene.active_checkpoint.is_empty(), "Selected stage checkpoint restored")
		current_scene.restart()
		await settle()
		check(current_scene.scene_file_path == scene_path, "Manual restart preserves selected stage")
		check(current_scene.active_checkpoint.is_empty(), "Manual restart resets checkpoint")
		while current_scene.entrance.active:
			await physics_frame
		current_scene.player.global_position = current_scene.get_node("TheaterStage/PlacementMarkers/Exit").global_position
		for tick in range(3):
			await physics_frame
		check(current_scene.exit_door.active and not current_scene.cleared, "Goal contact starts exit sequence")
		while current_scene.exit_door.active:
			await physics_frame
		check(current_scene.cleared, "Closing completion clears stage")
		current_scene.return_to_stage_select()
		await settle()
		check(current_scene.scene_file_path == "res://scenes/stage_select.tscn", "Clear can return to selection")
	print("Stage selection: %s" % ("PASS" if failures == 0 else "FAIL"))
	current_scene.queue_free()
	await settle()
	quit(0 if failures == 0 else 1)

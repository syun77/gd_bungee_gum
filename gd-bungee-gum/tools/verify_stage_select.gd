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

func toggle_menu() -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = &"pause_menu"
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()

func verify() -> void:
	var startup: String = ProjectSettings.get_setting("application/run/main_scene")
	check(startup == "res://scenes/game_time_attack.tscn", "F5 starts Time Attack directly")
	change_scene_to_file(startup)
	await settle()
	check(current_scene.time_attack, "Startup is Time Attack")
	current_scene._clear_stage()
	var results := current_scene.get_node("HUD").find_children("*", "Button", true, false)
	check(results.size() == 1, "Time Attack result offers only retry")
	toggle_menu()
	check(current_scene.pause_menu.is_open, "Time Attack menu opens after clear")
	current_scene.pause_menu.buttons[1].pressed.emit()
	await settle()
	check(current_scene.scene_file_path == "res://scenes/mode_select.tscn", "Time Attack menu returns to mode selection")
	var mode_buttons := current_scene.find_children("*", "Button", true, false)
	check(mode_buttons.size() == 2 and not mode_buttons[1].disabled, "Time Attack can be selected")
	check(mode_buttons[0].has_focus(), "Stage Mode has initial focus")
	mode_buttons[0].pressed.emit()
	await settle()
	check(current_scene.scene_file_path == "res://scenes/stage_select.tscn", "Stage Mode opens stage selection")
	var back_buttons := current_scene.find_children("*", "Button", true, false)
	back_buttons[3].pressed.emit()
	await settle()
	check(current_scene.scene_file_path == "res://scenes/mode_select.tscn", "Back opens mode selection")
	mode_buttons = current_scene.find_children("*", "Button", true, false)
	mode_buttons[0].pressed.emit()
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
	var pickup_counts: Dictionary = {}
	for layer_name in ["Foods", "Baguettes", "MusicNotes"]:
		var layer := current_scene.get_node("TheaterStage/" + layer_name)
		pickup_counts[layer_name] = layer.get_child_count()
		check(layer.get_child_count() > 0, "Theater has " + layer_name)
		var score_before: int = current_scene.score
		var pickup = layer.get_child(0)
		pickup.collect()
		pickup.collect()
		var points: int = {"Foods": 300, "Baguettes": 30, "MusicNotes": 10}[layer_name]
		check(current_scene.score == score_before + points, "Pickup awards points once: " + layer_name)
	var collected_score: int = current_scene.score
	check(collected_score >= 340, "Food, baguette and note award points")
	var first_checkpoint = current_scene.get_node("TheaterStage/Checkpoints/Checkpoint01")
	current_scene._on_checkpoint_reached(first_checkpoint)
	current_scene.restart(true)
	await settle()
	for layer_name in pickup_counts:
		check(current_scene.get_node("TheaterStage/" + layer_name).get_child_count() == pickup_counts[layer_name] - 1, "Death preserves " + layer_name)
	check(current_scene.score >= collected_score, "Death preserves score before any new spawn-contact pickup")
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
	toggle_menu()
	check(current_scene.pause_menu.is_open, "Menu action opens menu without HUD button")
	current_scene.pause_menu.buttons[1].pressed.emit()
	await settle()
	check(current_scene.scene_file_path == "res://scenes/stage_select.tscn", "Menu action returns to selection")
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
		var foods := current_scene.get_node("TheaterStage/Foods")
		var food_count: int = foods.get_child_count()
		var food = foods.get_child(0)
		food.global_position += Vector2(17, -9)
		food.collect()
		check(current_scene.collected_items.size() == 1, "Moved food records original placement")
		current_scene.restart(true)
		await settle()
		check(current_scene.scene_file_path == scene_path, "Death restart preserves selected stage")
		check(not current_scene.active_checkpoint.is_empty(), "Selected stage checkpoint restored")
		check(current_scene.get_node("TheaterStage/Foods").get_child_count() == food_count - 1, "Death keeps collected food absent")
		check(not current_scene.collected_items.is_empty(), "Death restores collected identities")
		current_scene.restart(true)
		await settle()
		check(current_scene.get_node("TheaterStage/Foods").get_child_count() == food_count - 1, "Repeated death keeps collected food absent")
		current_scene.restart()
		await settle()
		check(current_scene.scene_file_path == scene_path, "Manual restart preserves selected stage")
		check(current_scene.active_checkpoint.is_empty(), "Manual restart resets checkpoint")
		check(current_scene.get_node("TheaterStage/Foods").get_child_count() == food_count, "Manual retry restores items")
		check(current_scene.collected_items.is_empty(), "Manual retry clears collected identities")
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

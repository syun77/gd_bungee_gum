extends SceneTree
## Run with Godot --headless --path gd-bungee-gum --log-file /tmp/replay.log --script res://tools/verify_replay.gd.
var failures := 0
var store: Node
const TEST_PATH := "/tmp/bungee-gum-verify-replay.dat"

func _initialize() -> void:
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func wait_frames(count := 3) -> void:
	for i in count:
		await process_frame

func verify() -> void:
	store = root.get_node("ReplayStore")
	store.save_path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)
	store.load_latest()
	check(not store.available(), "No completed run means no replay")
	change_scene_to_file("res://scenes/game_time_attack.tscn")
	await wait_frames()
	var game = current_scene
	check(store.frames.size() > 0, "Scene entry starts recording entrance")
	check(game.pause_menu.buttons[3].disabled, "Replay action disabled without completed data")
	var first_frame: Dictionary = store.frames[0]
	var has_tiles := false
	for data in first_frame.changed.values():
		has_tiles = has_tiles or data.kind == "tiles"
	check(has_tiles, "Initial frame contains saved map artwork")
	var count: int = store.frames.size()
	game.pause_menu.open()
	await create_timer(0.08, true).timeout
	check(store.frames.size() == count, "Pause never adds replay time")
	game.pause_menu.close()
	game.entrance.step(game.entrance.TOTAL_TIME)
	game.gum.show()
	Input.action_press("move_right")
	for i in 12:
		await physics_frame
		await process_frame
	Input.action_release("move_right")
	check(store.frames.size() > count, "Actual physics ticks append frames")
	var final_position: Vector2 = game.player.sprite.global_position
	var sprite_id: int = game.player.sprite.get_instance_id()
	store.capture()
	check(store.previous.has(sprite_id), "Player animation recorded")
	var player_visual: Dictionary = store.previous[sprite_id]
	check(player_visual.transform.origin.is_equal_approx(final_position), "Recorded position uses actual sprite transform")
	check(not player_visual.texture.is_empty(), "Sprite texture is persistable")
	game.gum.fire(Vector2.UP)
	game.gum.step(0.01)
	store.capture()
	check(store.previous[-1].kind == "gum" and not store.previous[-1].ready, "Outbound gum path recorded")
	check(store.frames[-1].sounds.has(&"shoot"), "Sound cues recorded")
	var box = load("res://scenes/props/gum_box.tscn").instantiate()
	game.add_child(box)
	box.position = Vector2(400, 300)
	box.rotation = 0.7
	store.capture()
	var box_visual: Dictionary = store.previous[box.get_node("Color").get_instance_id()]
	check(box_visual.transform == box.get_node("Color").global_transform, "Rigid rotation and position recorded")
	var tiles: TileMapLayer = game.get_node("TheaterStage/TerrainTiles")
	var cell: Vector2i = tiles.get_used_cells()[0]
	tiles.erase_cell(cell)
	store.capture()
	check(store.frames[-1].changed[tiles.get_instance_id()].cells == tiles.tile_map_data, "Terrain changes recorded as tile deltas")
	box.free()
	store.capture()
	check(store.frames[-1].removed.size() >= 2, "Deleted objects remove all visuals")
	# Actual checkpoint death reload keeps the beginning, and replaces old visual IDs.
	count = store.frames.size()
	var initial_frame: Dictionary = store.frames[0]
	game.restart(true)
	await wait_frames(5)
	game = current_scene
	check(store.frames.size() > count and store.frames[0] == initial_frame, "Death reload preserves start-to-goal recording")
	check(store.game == game, "Recording follows replacement Game")
	# An unfinished run cannot overwrite the completed replay.
	check(not FileAccess.file_exists(TEST_PATH), "No replay file written before clear")
	game.entrance.step(game.entrance.TOTAL_TIME)
	game.best_time = 0.000001 # Avoid changing the user's separate Time Attack best.
	game.player.global_position = game.exit_door.global_position
	game._begin_exit()
	for i in 120:
		await physics_frame
		await process_frame
		if game.cleared:
			break
	check(game.cleared, "Actual exit sequence completes recording")
	check(store.available() and FileAccess.file_exists(TEST_PATH), "Goal saves complete replay")
	check(not is_instance_valid(store.game), "Clear stops capture")
	var recorded: Dictionary = store.latest.duplicate(true)
	store.latest = {}
	store.load_latest()
	check(store.latest == recorded, "Compressed disk roundtrip preserves every snapshot")
	var shared_settings = load("res://resources/game_settings.tres")
	var original_zoom: float = shared_settings.camera_normal_zoom
	shared_settings.camera_normal_zoom = original_zoom * 1.25
	game.pause_menu.open()
	check(not game.pause_menu.buttons[3].disabled, "Completed run enables replay action")
	game.pause_menu.buttons[3].pressed.emit()
	await wait_frames(5)
	var replay = current_scene
	check(replay.scene_file_path == "res://scenes/replay.tscn" and not paused, "Game menu launches unpaused replay")
	check(replay.get_node_or_null("Player") == null and replay.get_node_or_null("TheaterStage") == null, "Playback has no live gameplay scene")
	check(not replay.visuals.is_empty(), "Replay renders recorded visuals")
	check(replay.camera.zoom.is_equal_approx(Vector2.ONE * original_zoom * 1.25), "Saved run uses current shared normal zoom at playback entry")
	replay.settings = replay.settings.duplicate()
	shared_settings.camera_normal_zoom = original_zoom
	for zoom in [0.75, 1.5]:
		replay.settings.camera_normal_zoom = zoom
		var frame: Dictionary = recorded.frames[replay.cursor - 1].duplicate(true)
		frame["zoom"] = Vector2(3, 3)
		frame.sounds = []
		replay._apply_frame(frame)
		check(replay.camera.zoom.is_equal_approx(Vector2.ONE * zoom), "Playback uses current normal zoom instead of recorded zoom")
		check(replay.camera.position == frame.camera, "Changing zoom preserves recorded camera center")
	for node in replay.visuals.values():
		check(not node is PhysicsBody2D and not node is Area2D, "Playback visual is never a physics actor")
		if node is TileMapLayer:
			check(not node.collision_enabled and not node.navigation_enabled, "Replay tiles cannot affect physics")
			for i in node.tile_set.get_source_count():
				check(not node.tile_set.get_source(node.tile_set.get_source_id(i)) is TileSetScenesCollectionSource, "Replay tiles cannot spawn live pickups")
	replay.pause_menu.open()
	var cursor: int = replay.cursor
	await create_timer(0.05, true).timeout
	check(replay.cursor == cursor, "Replay pause freezes cursor")
	replay.pause_menu.close()
	# Advance the normal playback clock through the remaining saved ticks.
	replay._physics_process(float(store.latest.frames.size()) / store.latest.tick_rate + 1.0)
	check(replay.finished and replay.pause_menu.is_open, "Replay ends with replay/back controls")
	check(replay.score.text == "SCORE %d" % store.latest.frames[-1].score, "Final score reproduced")
	var expected: Dictionary = {}
	for frame in recorded.frames:
		for id in frame.removed:
			expected.erase(id)
		expected.merge(frame.changed, true)
	check(replay.visuals.size() == expected.size(), "Final visual set exactly matches recorded run")
	for id in expected:
		check(replay.visuals.has(id), "Recorded final visual exists")
		if replay.visuals.has(id):
			check(replay.visuals[id].transform == expected[id].transform, "Final transform reproduces recorded state without drift")
	check(store.latest == recorded, "Playback never changes saved run")
	replay.pause_menu.buttons[0].pressed.emit()
	await wait_frames()
	replay = current_scene
	check(not replay.finished and not paused, "Replay can restart from menu")
	replay.pause_menu.open()
	replay.pause_menu.buttons[1].pressed.emit()
	await wait_frames()
	check(current_scene.scene_file_path == "res://scenes/mode_select.tscn" and not paused, "Replay back returns to mode menu")
	var menu_buttons := current_scene.find_children("*", "Button", true, false)
	var replay_button: Button
	for button in menu_buttons:
		if button.text == "リプレイ再生":
			replay_button = button
	check(replay_button != null and not replay_button.disabled, "Mode menu has enabled replay action")
	replay_button.pressed.emit()
	await wait_frames()
	check(current_scene.scene_file_path == "res://scenes/replay.tscn", "Mode menu launches replay")
	# Manual retry starts a new run while retaining the previous completed run.
	paused = false
	change_scene_to_file("res://scenes/game.tscn")
	await wait_frames()
	game = current_scene
	store.capture()
	count = store.frames.size()
	game.restart()
	await wait_frames()
	check(store.frames.size() < count + 4 and store.latest == recorded, "Manual retry resets recording and retains saved replay")
	store.suspend(false)
	check(not store.valid_recording({}), "Missing replay schema rejected")
	var invalid: Dictionary = recorded.duplicate(true)
	invalid.frames[0].erase("camera")
	check(not store.valid_recording(invalid), "Malformed frame rejected")
	invalid = recorded.duplicate(true)
	invalid.frames[0].changed.values()[0].kind = "unknown"
	check(not store.valid_recording(invalid), "Unknown visual schema rejected")
	# A write failure retains the completed replay and its on-disk bytes.
	store.begin(current_scene)
	store.save_path = "/tmp/bungee-replay-missing-directory/replay.dat"
	store.finish()
	check(not store.failure.is_empty() and store.latest == recorded, "Save failure retains previous completed run")
	store.save_path = TEST_PATH
	var file := FileAccess.open_compressed(TEST_PATH, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	file.store_var({"version": -1})
	file.close()
	store.load_latest()
	check(not store.available(), "Unsupported saved replay disabled safely")
	DirAccess.remove_absolute(TEST_PATH)
	print("Replay: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

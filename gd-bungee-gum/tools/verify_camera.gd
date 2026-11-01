extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		failures += 1

func key(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_X
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func verify() -> void:
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	# Isolate camera timing without changing the shared resource on disk.
	game.settings = game.settings.duplicate()
	var settings = game.settings
	game.gum.settings = settings
	settings.maximum_length = 900.0
	settings.camera_hold_delay = 0.2
	check(game.camera.zoom.is_equal_approx(Vector2.ONE * settings.camera_normal_zoom), "Spawn uses close normal zoom")
	settings.camera_zoom_response = 0.0
	key(true)
	game._update_camera(settings.camera_hold_delay * 0.5)
	check(is_equal_approx(game.camera.zoom.x, settings.camera_normal_zoom), "Short X press keeps close view")
	game._update_camera(settings.camera_hold_delay)
	check(is_equal_approx(game.camera.zoom.x, settings.camera_hold_zoom), "Physical held X widens view")
	key(false)
	game._update_camera(0.01)
	check(is_equal_approx(game.camera.zoom.x, settings.camera_normal_zoom) and game.camera_hold_time == 0.0, "Release resets hold and restores normal view")
	# Real ray attachment provides the connection; only the measured path is varied.
	check(game.gum.attach_at(game.gum.origin() + Vector2.UP * 800.0), "Camera fixture attaches to saved-map ceiling")
	game.gum.path.length = settings.camera_gum_zoom_start
	game._update_camera(0.01)
	check(is_equal_approx(game.camera.zoom.x, settings.camera_normal_zoom), "Short connection stays close")
	key(true)
	game._update_camera(1.0)
	check(is_equal_approx(game.camera.zoom.x, settings.camera_normal_zoom) and game.camera_hold_time == 0.0, "Attached X never widens view or accumulates hold")
	key(false)
	game.gum.path.length = (settings.camera_gum_zoom_start + settings.camera_gum_zoom_end) * 0.5
	game._update_camera(0.01)
	check(is_equal_approx(game.camera.zoom.x, (settings.camera_normal_zoom + settings.camera_long_gum_zoom) * 0.5), "Path midpoint interpolates zoom")
	game.gum.path.length = settings.camera_gum_zoom_end + 100.0
	key(true)
	game._update_camera(settings.camera_hold_delay)
	check(is_equal_approx(game.camera.zoom.x, settings.camera_long_gum_zoom), "Long connection wins over held X and clamps at maximum distance")
	key(false)
	settings.camera_gum_zoom_end = settings.camera_gum_zoom_start
	game._update_camera(0.01)
	check(is_equal_approx(game.camera.zoom.x, settings.camera_long_gum_zoom), "Equal thresholds remain finite")
	key(true)
	game.gum.detach()
	game._update_camera(0.01)
	check(game.camera_hold_time == 0.0 and is_equal_approx(game.camera.zoom.x, settings.camera_normal_zoom), "Detach resets held X timing")
	key(false)
	# Start wide to measure the smooth return independently of hold timing.
	game.camera.zoom = Vector2.ONE * settings.camera_long_gum_zoom
	settings.camera_zoom_response = 5.0
	var initial: float = game.camera.zoom.x
	game._update_camera(0.1)
	check(game.camera.zoom.x > initial and game.camera.zoom.x < settings.camera_normal_zoom, "Detach smoothly restores close view")
	var one_step: float = game.camera.zoom.x
	game.camera.zoom = Vector2.ONE * initial
	game._update_camera(0.05)
	game._update_camera(0.05)
	check(is_equal_approx(game.camera.zoom.x, one_step), "Exponential transition is independent of timestep subdivision")
	check(game.camera.position == game.player.position, "Camera continues player follow")
	game.free()
	if failures == 0:
		print("PASS: camera zoom")
	quit(1 if failures else 0)

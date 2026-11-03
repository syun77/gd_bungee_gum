extends SceneTree
var failures := 0
const Layout = preload("res://scripts/stage_layout.gd")
func _initialize() -> void:
	call_deferred("verify")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func ticks(count := 4) -> void:
	for i in count:
		await physics_frame
func verify() -> void:
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	await ticks()
	var points = game.get_node("TheaterStage/Checkpoints").get_children()
	check(points.size() == Layout.CHECKPOINTS.size(), "Saved checkpoint placements match layout")
	for i in points.size():
		check(points[i].position == Layout.CHECKPOINTS[i], "Placement matches layout")
		check(points[i].collision_layer == 0 and points[i].collision_mask == 2, "Checkpoint is non-solid player-only trigger")
		var floor_ray := PhysicsRayQueryParameters2D.create(points[i].global_position + Vector2(0,-2), points[i].global_position + Vector2(0,4), 1)
		check(not game.get_world_2d().direct_space_state.intersect_ray(floor_ray).is_empty(), "Checkpoint respawn has solid floor support")
		var ray := PhysicsRayQueryParameters2D.create(points[i].global_position + Vector2(0,-80), points[i].global_position + Vector2(0,-4), 53)
		ray.collide_with_areas = true
		var hit: Dictionary = game.get_world_2d().direct_space_state.intersect_ray(ray)
		check(hit.is_empty() or hit.collider != points[i], "Gum ignores checkpoint")
	var art: Sprite2D = points[0].get_node("Sprite2D")
	var image := art.texture.get_image()
	var cell_size := Vector2(image.get_size()) / Vector2(art.hframes, art.vframes)
	for frame_index in 8:
		art.frame = frame_index
		var start := Vector2(frame_index % 4, frame_index / 4) * cell_size
		var bottom := 0
		for y in range(ceili(start.y), floori(start.y + cell_size.y)):
			for x in range(ceili(start.x), floori(start.x + cell_size.x)):
				if image.get_pixel(x, y).a >= 0.5:
					bottom = y + 1
		var visible_bottom := art.position.y + (bottom - start.y - cell_size.y * 0.5) * art.scale.y
		check(absf(visible_bottom) < 0.15, "Every animation frame base touches checkpoint floor origin")
	art.frame = 0
	var point = points[0]
	check(not point.activated and point.get_node("Sprite2D").frame == 0, "Initial ring face")
	game.player.global_position = point.respawn_position()
	await ticks(6)
	check(point.activated and game.active_checkpoint == game.get_path_to(point), "Actual player contact activates checkpoint")
	point.set_process(false)
	point.elapsed = 0.0
	check(point.get_node("Sprite2D").hframes == 4 and point.get_node("Sprite2D").vframes == 2, "Eight-frame sheet without rebound")
	for frame in 8:
		point._process(0.055)
		check(point.get_node("Sprite2D").frame == mini(frame + 1,7), "Animation traverses flip frames")
	check(not point.is_processing(), "Animation settles on check")
	point._process(1.0)
	check(point.get_node("Sprite2D").frame == 7, "Final check remains stationary")
	game.player.external_velocity = Vector2(120,500)
	game.player.position.y = game.settings.restart_y + 1
	game._physics_process(1.0/60.0)
	check(game.restarting, "Pit death requests reload")
	game.restart()
	await scene_changed
	game = current_scene
	game.set_physics_process(false)
	point = game.get_node("TheaterStage/Checkpoints/Checkpoint01")
	check(game.player.global_position.distance_to(point.respawn_position()) < 4, "Pit death restores checkpoint instead of entrance")
	check(point.activated and point.get_node("Sprite2D").frame == 7, "Reload preserves activated face")
	check(game.player.external_velocity.is_zero_approx() and not game.gum.connected(), "Respawn clears velocity and gum")
	check(not has_meta(game.RESPAWN_META), "Reload handoff consumed")
	var second = game.get_node("TheaterStage/Checkpoints/Checkpoint02")
	game.player.global_position = second.respawn_position()
	await ticks(6)
	check(game.active_checkpoint == game.get_path_to(second), "Most recently touched checkpoint replaces earlier one")
	# Real stationary spike overlap uses the same checkpoint death route.
	var spike = load("res://scenes/hazards/spikes.tscn").instantiate()
	spike.position = game.player.global_position + Vector2(0,-26)
	game.add_child(spike)
	await ticks()
	game._physics_process(1.0/60.0)
	check(is_instance_valid(game.death_effect), "Spike overlap starts disappearance")
	game._physics_process(0.61)
	await scene_changed
	game = current_scene
	game.set_physics_process(false)
	second = game.get_node("TheaterStage/Checkpoints/Checkpoint02")
	check(game.player.global_position.distance_to(second.respawn_position()) < 4, "Spike death uses latest checkpoint")
	game.restart()
	await scene_changed
	game = current_scene
	game.set_physics_process(false)
	check(game.active_checkpoint.is_empty(), "Manual restart clears checkpoint")
	check(game.player.global_position.distance_to(game.get_node("TheaterStage/PlacementMarkers/PlayerSpawn").global_position) < 4, "Manual restart returns to entrance")
	game.player.position.y = game.settings.restart_y + 1
	game._physics_process(1.0/60.0)
	await scene_changed
	game = current_scene
	game.set_physics_process(false)
	check(game.active_checkpoint.is_empty(), "Death before first checkpoint retains entrance")
	print("Checkpoint verification: ", "PASS" if failures == 0 else "FAIL %d" % failures)
	quit(0 if failures == 0 else 1)

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
	game._physics_process(game.entrance.TOTAL_TIME)
	current_scene = game
	game.set_physics_process(false)
	var layer: TileMapLayer = game.get_node("TheaterStage/Spikes")
	check(layer.get_used_cells().size() == Layout.SPIKES.size(), "Saved spikes match layout")
	layer.set_cell(Vector2i(10, 10), 0, Vector2i.ZERO, 0)
	await ticks()
	check(layer.get_child_count() == Layout.SPIKES.size() + 1, "Painted spike instantiates")
	var hazard: Area2D
	for child in layer.get_children():
		if child.global_position.distance_to(Vector2(336, 336)) < 1:
			hazard = child
	check(hazard.collision_layer == 64 and hazard.collision_mask == 0, "Hazards are non-solid isolated areas")
	check(hazard.get_node("Sprite2D").texture.get_size() == Vector2(32, 32), "32px sprite")
	var center := hazard.global_position
	var start := Transform2D(0, center + Vector2(-140, 0))
	check(not game._touches_spikes(start, Vector2.ZERO), "Safe nearby position")
	check(game._touches_spikes(Transform2D(0, center), Vector2.ZERO), "Initial overlap detected")
	check(game._touches_spikes(start, Vector2(280, 0)), "Fast horizontal traversal cannot tunnel")
	check(game._touches_spikes(Transform2D(0, center + Vector2(0, -140)), Vector2(0, 280)), "Fast vertical traversal cannot tunnel")
	check(not game._touches_spikes(Transform2D(0, center + Vector2(-140, -100)), Vector2(280, 0)), "Passing above spikes is safe")
	var query := PhysicsRayQueryParameters2D.create(center + Vector2(0,-60), center, 53)
	query.collide_with_areas = true
	check(game.get_world_2d().direct_space_state.intersect_ray(query).is_empty(), "Gum ignores spikes")
	layer.erase_cell(Vector2i(10, 10))
	await ticks()
	check(not game._touches_spikes(start, Vector2(280, 0)), "Erasing removes hazard")
	# Real fixed-step movement through an entire tile in one tick.
	layer.set_cell(Vector2i(10, 10), 0, Vector2i.ZERO, 0)
	await ticks()
	game.player.global_position = center + Vector2(-100, 26)
	game.player.external_velocity = Vector2(18000, 0)
	game._physics_process(1.0 / 60.0)
	check(is_instance_valid(game.death_effect), "Live sweep begins disappearance")
	check(not game.player.visible and not game.gum.visible, "Player and gum disappear immediately")
	check(game.death_effect.global_position.distance_to(center) < 80, "Sweep effect remains at contact, not overshot destination")
	var effect = game.death_effect
	game._die_on_spikes(center)
	check(game.death_effect == effect, "Repeated hazard does not duplicate effect")
	var frozen_position: Vector2 = game.player.position
	game._physics_process(0.3)
	check(not game.restarting and game.death_effect.frame == 9, "Death plays halfway before reload")
	check(game.player.position == frozen_position, "Dead player cannot simulate movement")
	game._physics_process(0.31)
	await scene_changed
	check(is_instance_valid(current_scene) and current_scene != game, "Deferred restart creates new Game once")
	if is_instance_valid(current_scene):
		var fresh = current_scene
		check(not fresh.restarting, "Restart state cleared")
		check(not fresh.gum.connected(), "Restart clears gum")
		check(fresh.player.global_position.distance_to(fresh.get_node("TheaterStage/PlacementMarkers/PlayerSpawn").global_position) < 4, "Player respawns at stage entrance")
		fresh.set_physics_process(false)
		# Stationary overlap is lethal even when player movement is locked by food reel.
		var spike = load("res://scenes/hazards/spikes.tscn").instantiate()
		spike.position = fresh.player.global_position + Vector2(0, -26)
		fresh.add_child(spike)
		await ticks()
		fresh._physics_process(1.0 / 60.0)
		check(is_instance_valid(fresh.death_effect), "Stationary overlap starts disappearance")
		fresh._physics_process(0.61)
		await ticks()
	print("Spike verification: ", "PASS" if failures == 0 else "FAIL %d" % failures)
	quit(0 if failures == 0 else 1)

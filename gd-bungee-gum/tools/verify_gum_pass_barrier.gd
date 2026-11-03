extends SceneTree
## Saved tile: full body collision, gum ray/path transparency, no one-way behavior.
const Layout = preload("res://scripts/stage_layout.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func verify() -> void:
	var stage = load("res://scenes/stages/theater_stage.tscn").instantiate()
	var saved: TileMapLayer = stage.get_node("GumPassBarriers")
	root.add_child(stage)
	check(saved.collision_enabled, "Saved barrier collisions enabled")
	var expected := 0
	for rect in Layout.GUM_PASS_BARRIERS:
		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y):
				expected += 1
				check(saved.get_cell_source_id(Vector2i(x, y)) == 3, "Saved screen matches layout")
	check(saved.get_used_cells().size() == expected, "Saved screen count matches layout")
	var layer := TileMapLayer.new()
	layer.tile_set = saved.tile_set
	layer.set_cell(Vector2i.ZERO, 3, Vector2i.ZERO)
	root.add_child(layer)
	var player = load("res://scenes/characters/player.tscn").instantiate()
	root.add_child(player)
	var box = load("res://scenes/props/gum_box.tscn").instantiate()
	box.freeze = true
	box.position = Vector2(1000, 1000)
	root.add_child(box)
	var gum = load("res://scripts/gum_connection.gd").new()
	gum.settings = load("res://resources/game_settings.tres").duplicate()
	gum.player = player
	root.add_child(gum)
	await physics_frame
	await process_frame
	await physics_frame
	for ring_cell in [Vector2i(5, 12), Vector2i(60, 14)]:
		var ring_center := Vector2(ring_cell * 32) + Vector2(16, 16)
		player.position = ring_center + Vector2(0, 178)
		check(player.test_move(player.global_transform, Vector2(0, -144)), "Saved screen blocks upward body passage")
		check(gum.attach_at(ring_center) and gum.target == stage.get_node("GumAnchors"), "Saved screen passes gum to ring above")
		gum.step(1.0 / 60.0)
		check(gum.connected(), "Saved screen preserves connection through frame")
		gum.detach()
	stage.free()
	var target := StaticBody2D.new()
	target.position = Vector2(100, 16)
	target.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(8, 64)
	shape.shape = rectangle
	target.add_child(shape)
	root.add_child(target)
	await physics_frame
	await process_frame
	await physics_frame
	var center := Vector2(16, 16)
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		player.position = center + direction * 100 + Vector2(0, 26)
		check(player.test_move(player.global_transform, -direction * 100), "Player blocked from %s" % direction)
		box.position = center + direction * 100
		check(box.test_move(box.global_transform, -direction * 100), "Box blocked from %s" % direction)
		var query := PhysicsRayQueryParameters2D.create(center + direction * 40, center - direction * 40, 64)
		check(not layer.get_world_2d().direct_space_state.intersect_ray(query).is_empty(), "Filled collision includes transparent center")
	box.position = Vector2(1000, 1000)
	player.position = Vector2(-50, 50)
	check(gum.attach_at(target.position) and gum.target == target, "Actual gum ray passes barrier and attaches behind it")
	gum.step(1.0 / 60.0)
	check(gum.state == gum.State.ATTACHED, "Barrier does not interrupt attached path")
	player.set_collision_mask_value(4, false)
	player.position = Vector2(16, -80)
	check(player.test_move(player.global_transform, Vector2(0, 120)), "Drop-through mask does not disable barrier")
	var data := (layer.tile_set.get_source(3) as TileSetAtlasSource).get_tile_data(Vector2i.ZERO, 0)
	check(not data.is_collision_polygon_one_way(2, 0), "Full collision, including underside")
	gum.free()
	player.free()
	box.free()
	target.free()
	layer.free()
	print("Gum-pass barrier: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

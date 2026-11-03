extends SceneTree
var failures := 0
var pickups := 0
const Layout = preload("res://scripts/stage_layout.gd")
func _initialize() -> void:
	call_deferred("verify")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func ticks() -> void:
	for i in 5:
		await physics_frame
func verify() -> void:
	var stage = load("res://scenes/stages/theater_stage.tscn").instantiate()
	root.add_child(stage)
	var layer: TileMapLayer = stage.get_node("Foods")
	await ticks()
	check(layer.get_used_cells().size() == 36, "Saved map has36 pickups")
	check(layer.get_child_count() == 36, "Saved foods instantiate")
	var dishes := {}
	var sections := [0, 0, 0, 0, 0, 0]
	for food in Layout.FOODS:
		var cell := Vector2i(food.x, food.y)
		check(layer.get_cell_alternative_tile(cell) == food.z, "Saved food matches layout")
		dishes[food.z] = true
		sections[mini((food.x - 2) / 26, 5)] += 1
		var supported := false
		for rect in Layout.TERRAIN + Layout.ONE_WAY_FLOORS:
			check(not rect.has_point(cell), "Food is outside terrain")
			supported = supported or (rect.position.y == cell.y + 1 and cell.x >= rect.position.x and cell.x < rect.end.x)
		check(supported, "Food has a supporting floor directly below")
	check(dishes.size() == 11, "All eleven dishes appear in map")
	check(sections == [6, 6, 6, 6, 6, 6], "Six foods in each section")
	layer.clear()
	await ticks()
	var source: TileSetScenesCollectionSource = layer.tile_set.get_source(0)
	check(source.get_scene_tiles_count() == 11, "All eleven foods are paintable")
	var player = load("res://scenes/characters/player.tscn").instantiate()
	player.position = Vector2(-1000, -1000)
	root.add_child(player)
	var box := RigidBody2D.new()
	box.collision_layer = 4
	box.gravity_scale = 0
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	box.add_child(shape)
	root.add_child(box)
	for id in 11:
		var cell := Vector2i(200 + id * 3, -10)
		layer.set_cell(cell, 0, Vector2i.ZERO, id)
		await ticks()
		check(layer.get_child_count() == 1, "Painting instantiates one food")
		if layer.get_child_count() != 1:
			continue
		var food = layer.get_child(0)
		check(food.get_node("Sprite2D").texture.get_size() == Vector2(64, 64), "Original food texture preserved")
		food.collected.connect(func(_id): pickups += 1)
		box.position = food.global_position
		await ticks()
		check(is_instance_valid(food), "Props cannot collect")
		player.position = food.global_position + Vector2(0, 26)
		await ticks()
		check(not is_instance_valid(food), "Player contact collects scene tile")
		check(pickups == id + 1, "Each item signals exactly once")
		layer.erase_cell(cell)
		player.position = Vector2(-1000, -1000)
	stage.queue_free()
	await process_frame
	stage = load("res://scenes/stages/theater_stage.tscn").instantiate()
	root.add_child(stage)
	layer = stage.get_node("Foods")
	await ticks()
	check(layer.get_child_count() == 36, "Reload restores authored item availability")
	print("Food collectibles: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

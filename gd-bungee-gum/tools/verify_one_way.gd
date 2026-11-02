extends SceneTree
## Real saved TileMap collisions, controller passage/landing/kick and rigid support.
const Layout = preload("res://scripts/stage_layout.gd")
var player: CharacterBody2D
var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func ticks(count: int, kick := false) -> void:
	for i in count:
		await physics_frame
		player.simulate(1.0 / 60.0, kick and i == 0)
		await process_frame

func verify() -> void:
	var stage = load("res://scenes/stages/theater_stage.tscn").instantiate()
	root.add_child(stage)
	var layer: TileMapLayer = stage.get_node("OneWayPlatforms")
	check(layer.collision_enabled, "One-way layer must generate collision")
	var expected_cells := 0
	for rect in Layout.ONE_WAY_FLOORS:
		expected_cells += rect.size.x
	check(layer.get_used_cells().size() == expected_cells, "Saved map must contain all landing shelves")
	# Isolate collision semantics using the saved TileSet and a clear area of entrance floor.
	layer.clear()
	for x in range(10, 16):
		layer.set_cell(Vector2i(x, 17), 1, Vector2i(0 if x == 10 else (2 if x == 15 else 1), 0))
	for x in 4:
		var data := (layer.tile_set.get_source(1) as TileSetAtlasSource).get_tile_data(Vector2i(x, 0), 0)
		check(data.is_collision_polygon_one_way(0, 0), "All four tiles need one-way collision")
	player = load("res://scenes/characters/player.tscn").instantiate()
	player.settings = load("res://resources/game_settings.tres").duplicate()
	player.settings.landing_diagnostics = false
	player.settings.jump_diagnostics = false
	player.settings.pinning_diagnostics = false
	root.add_child(player)
	await ticks(2)
	# Launch from entirely below shelf: the real controller must pass upward then land.
	player.position = Vector2(400, 610)
	player.external_velocity = Vector2(0, -600)
	var min_y := player.position.y
	for i in 100:
		await ticks(1)
		min_y = minf(min_y, player.position.y)
	check(min_y < 530, "Player must pass upward through the tile")
	check(player.is_on_floor() and absf(player.position.y - 544) < 1, "Player must settle on platform top")
	await ticks(1, true)
	check(player.external_velocity.y < -300 and not player.is_on_floor(), "Platform must allow contact kick")
	# Fast descent and adjacent tile seams must remain supported.
	for x in [336, 352, 368, 384, 400, 416, 432, 448, 464, 480, 496]:
		player.position = Vector2(x, 460)
		player.external_velocity = Vector2(0, 1000)
		await ticks(30)
		check(player.is_on_floor() and absf(player.position.y - 544) < 1, "Fast landing/seam at x=%s" % x)
	# Capsule corners must use the actual tile top instead of its rounded contact normal.
	for edge in [320.0, 512.0]:
		var outward := -1.0 if edge == 320.0 else 1.0
		for offset in [0.0, 5.0, 7.0, 8.0]:
			player.position = Vector2(edge + outward * offset, 490)
			player.external_velocity = Vector2(0, 300)
			var start_x := player.position.x
			await ticks(60)
			check(player.is_on_floor() and player.position.y < 554,
				"Extreme tile edge must retain support edge=%s offset=%s position=%s" % [edge, offset, player.position])
			check(absf(player.position.x - start_x) < 0.1,
				"Tile edge must not create lateral drift edge=%s offset=%s" % [edge, offset])
	# The shelf sides must not block horizontal travel when feet are below its top.
	player.position = Vector2(290, 580)
	player.external_velocity = Vector2(600, 0)
	await ticks(12)
	check(player.position.x > 390, "Platform side must allow passage")
	player.position = Vector2(160, 640)
	player.external_velocity = Vector2.ZERO
	await ticks(3)
	var box: RigidBody2D = load("res://scenes/props/gum_box.tscn").instantiate()
	check(box.collision_mask == 9, "Rigid scene must include terrain and one-way layers")
	box.position = Vector2(400, 600)
	root.add_child(box)
	await ticks(2)
	box.linear_velocity = Vector2(0, -600)
	var box_min := box.position.y
	for i in 120:
		await ticks(1)
		box_min = minf(box_min, box.position.y)
	check(box_min < 515, "Rigid box must pass upward")
	check(absf(box.position.y - 524) < 2 and absf(box.linear_velocity.y) < 2, "Rigid box must rest on tile")
	var query := PhysicsRayQueryParameters2D.create(Vector2(400, 450), Vector2(400, 590), 5)
	query.exclude = [box.get_rid(), player.get_rid()]
	check(stage.get_world_2d().direct_space_state.intersect_ray(query).is_empty(), "Gum ray must pass through shelf")
	box.free()
	# Painting and erasing must update native collision without authored StaticBody shapes.
	layer.clear()
	layer.set_cell(Vector2i(12, 17), 1, Vector2i(3, 0))
	await ticks(3)
	player.position = Vector2(400, 470)
	player.external_velocity = Vector2.ZERO
	await ticks(45)
	check(player.is_on_floor() and absf(player.position.y - 544) < 1, "Painted single tile must support player")
	layer.erase_cell(Vector2i(12, 17))
	await ticks(45)
	check(player.is_on_floor() and absf(player.position.y - 640) < 1, "Erasing a tile must remove its collision")
	player.free()
	stage.free()
	if failures == 0:
		print("PASS: one-way TileMap upward/side passage, fast/seam landings, contact kick, rigid box, gum passage and paint/erase")
	quit(1 if failures else 0)

extends SceneTree
## Checks saved authored terrain, native one-way shelves and clear placements.
const Layout = preload("res://scripts/stage_layout.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func verify() -> void:
	var stage: Node2D = load("res://scenes/stages/theater_stage.tscn").instantiate()
	root.add_child(stage)
	await physics_frame
	await physics_frame
	var terrain: TileMapLayer = stage.get_node("TerrainTiles")
	var platforms: TileMapLayer = stage.get_node("OneWayPlatforms")
	var body: StaticBody2D = stage.get_node("Terrain")
	check(body.get_child_count() == Layout.TERRAIN.size(), "One static shape per authored rectangle")
	check(not terrain.collision_enabled and platforms.collision_enabled, "Only platform tiles generate native collision")
	var terrain_cells := {}
	for rect in Layout.TERRAIN:
		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y):
				terrain_cells[Vector2i(x, y)] = true
	check(terrain.get_used_cells().size() == terrain_cells.size(), "Saved terrain count matches authored layout")
	for x in Layout.SIZE.x:
		for y in Layout.SIZE.y:
			var cell := Vector2i(x, y)
			var query := PhysicsPointQueryParameters2D.new()
			query.position = Vector2(cell * Layout.TILE) + Vector2.ONE * 16
			query.collision_mask = 1
			var solid := not stage.get_world_2d().direct_space_state.intersect_point(query).is_empty()
			check(solid == terrain_cells.has(cell), "Static collision matches authored grid at %s" % cell)
			check((terrain.get_cell_source_id(cell) == 0) == solid, "Terrain art matches collision at %s" % cell)
	var platform_cells := {}
	for rect in Layout.ONE_WAY_FLOORS:
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, rect.position.y)
			platform_cells[cell] = true
			check(not terrain_cells.has(cell), "Shelf must not overlap solid terrain")
			check(platforms.get_cell_source_id(cell) == 1, "Shelf uses one-way atlas")
			var query := PhysicsPointQueryParameters2D.new()
			query.position = Vector2(cell * Layout.TILE) + Vector2(16, 2)
			query.collision_mask = 8
			check(not stage.get_world_2d().direct_space_state.intersect_point(query).is_empty(), "Shelf art has native collision")
	check(platforms.get_used_cells().size() == platform_cells.size(), "No unauthored shelf cells")
	for marker_name in Layout.MARKERS:
		var position: Vector2 = stage.get_node("PlacementMarkers/" + marker_name).position
		check(position == Layout.MARKERS[marker_name], "Saved marker matches layout")
		var query := PhysicsPointQueryParameters2D.new()
		query.position = position - Vector2(0, 1)
		query.collision_mask = 9
		check(stage.get_world_2d().direct_space_state.intersect_point(query).is_empty(), "Marker is clear: " + marker_name)
	var geometry = load("res://scripts/gum_terrain_geometry.gd").new()
	geometry.refresh(stage, 1.0)
	check(not geometry.unsupported and geometry.corners.size() > 0, "Stage exposes valid gum wrapping geometry")
	if failures == 0:
		print("PASS: saved map ", terrain_cells.size(), " solid cells, ", body.get_child_count(), " shapes, ", platform_cells.size(), " one-way cells, ", geometry.corners.size(), " gum corners and clear markers")
	stage.free()
	quit(1 if failures else 0)

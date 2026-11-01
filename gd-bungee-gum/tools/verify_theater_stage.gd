extends SceneTree
## Validates the saved map, static collision coverage and reserved placements.

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var stage := load("res://scenes/stages/theater_stage.tscn").instantiate() as Node2D
	root.add_child(stage)
	await physics_frame
	await physics_frame
	var terrain := stage.get_node("TerrainTiles") as TileMapLayer
	var body := stage.get_node("Terrain") as StaticBody2D
	assert(terrain.get_used_cells().size() == 1222)
	assert(body.get_child_count() == 24)
	assert(not terrain.collision_enabled)
	for cell in terrain.get_used_cells():
		var point := Vector2(cell * 32) + Vector2(16, 16)
		var query := PhysicsPointQueryParameters2D.new()
		query.position = point
		query.collision_mask = 1
		assert(not stage.get_world_2d().direct_space_state.intersect_point(query).is_empty(), "Missing terrain collision")
	for name in ["PlayerSpawn", "LightBoxSpawn", "HeavyBoxSpawn", "ProjectileEmitter", "ProjectileTarget", "Exit"]:
		var query := PhysicsPointQueryParameters2D.new()
		query.position = stage.get_node("PlacementMarkers/" + name).position
		query.collision_mask = 1
		assert(stage.get_world_2d().direct_space_state.intersect_point(query).is_empty(), "Marker inside terrain: " + name)
	var geometry = load("res://scripts/gum_terrain_geometry.gd").new()
	geometry.refresh(stage, 1.0)
	assert(not geometry.unsupported, "Stage contains unsupported gum wrapping geometry")
	assert(geometry.corners.size() == 62, "Collision union must expose 62 convex corners")
	print("PASS: saved scene, 1222 tile centers covered by static collision, 24 shapes, six clear placement markers.")
	stage.queue_free()
	quit()

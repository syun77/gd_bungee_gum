extends SceneTree
const Layout = preload("res://scripts/music_note_layout.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("verify")
func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
func verify() -> void:
	for entry in [["theater_stage", Layout.RESTAURANT], ["stage_2", Layout.TERRACE], ["stage_3", Layout.KITCHEN]]:
		var stage = load("res://scenes/stages/%s.tscn" % entry[0]).instantiate()
		root.add_child(stage)
		await process_frame
		await physics_frame
		var notes: TileMapLayer = stage.get_node("MusicNotes")
		check(notes.get_used_cells().size() == entry[1].size(), "%s saved note count" % entry[0])
		check(notes.get_child_count() == entry[1].size(), "%s animated instances spawn" % entry[0])
		for note in notes.get_children():
			check(note.has_method("collect"), "%s scene tile has pickup script" % entry[0])
		var shape := RectangleShape2D.new()
		shape.size = Vector2(24, 28)
		for cell in entry[1]:
			check(notes.get_cell_source_id(cell) == 0, "%s saved cell %s" % [entry[0], cell])
			var point := notes.to_global(notes.map_to_local(cell))
			var query := PhysicsShapeQueryParameters2D.new()
			query.shape = shape
			query.transform = Transform2D(0.0, point)
			query.collision_mask = 1 | 8 | 64
			query.collide_with_areas = true
			var hits := notes.get_world_2d().direct_space_state.intersect_shape(query)
			check(hits.is_empty(), "%s note %s intersects terrain/platform/hazard" % [entry[0], cell])
			var foods: TileMapLayer = stage.get_node("Foods")
			for food_cell in foods.get_used_cells():
				var distance := point.distance_to(foods.to_global(foods.map_to_local(food_cell)))
				check(distance >= 48.0, "%s note %s overlaps food %s" % [entry[0], cell, food_cell])
		print(entry[0], ": ", notes.get_child_count(), " notes checked")
		stage.free()
		await physics_frame
	if failures == 0:
		print("PASS: all saved route-note cells/instances, terrain/hazard and food clearance")
	quit(1 if failures else 0)

extends SceneTree
const Exchange = preload("res://addons/mapedit/stage_exchange.gd")

# Run with --headless --editor to exercise the actual scene history.
func _initialize() -> void:
	create_timer(10.0).timeout.connect(func() -> void: quit(1))
	call_deferred("verify")

func verify() -> void:
	var plugin := EditorPlugin.new()
	for path in Exchange.WIDTHS:
		EditorInterface.open_scene_from_path(path)
		for i in 10:
			await process_frame
		var stage := EditorInterface.get_edited_scene_root()
		assert(stage != null and stage.scene_file_path == path)
		var before := Exchange.snapshot(stage)
		var data := before.duplicate(true)
		data.base = Exchange.token(before)
		data = JSON.parse_string(JSON.stringify(data))
		assert(Exchange.validate(stage, before, data) == "")
		var no_op := Exchange.diff(before, data)
		assert(no_op.old.is_empty() and no_op.next.is_empty() and no_op.markers.is_empty())
		var invalid := data.duplicate(true)
		invalid.cells.append(invalid.cells[0])
		assert(Exchange.validate(stage, before, invalid).contains("Duplicate"))
		invalid = data.duplicate(true)
		invalid.cells[0].tile[0] = 999
		assert(Exchange.validate(stage, before, invalid).contains("Unknown"))
		invalid = data.duplicate(true)
		invalid.stage = "res://other.tscn"
		assert(Exchange.validate(stage, before, invalid).contains("match"))
		data.cells.remove_at(0)
		data.markers["PlacementMarkers/PlayerSpawn"][0] += 32
		var changes := Exchange.diff(before, data)
		assert(changes.terrain_changed)
		var history := plugin.get_undo_redo()
		var old_shapes := stage.get_node("Terrain").get_children()
		var old_children := stage.get_children()
		var decor := stage.get_node_or_null("BackgroundDecor") as TileMapLayer
		var decor_data := decor.tile_map_data if decor else PackedByteArray()
		Exchange.commit(history, stage, changes)
		assert(Exchange.snapshot(stage).cells.size() == data.cells.size())
		assert(Exchange.snapshot(stage).markers == data.markers)
		assert(not decor or decor.tile_map_data == decor_data)
		for child in stage.get_children():
			if child is Line2D and str(child.name).begins_with("Rim"):
				assert(child.owner == stage)
		assert(Exchange.validate(stage, Exchange.snapshot(stage), data).contains("changed"))
		var terrain_cells := {}
		for shape in stage.get_node("Terrain").get_children():
			assert(shape.owner == stage)
			var size: Vector2 = shape.shape.size
			var start := Vector2i((shape.position - size / 2) / 32)
			for y in int(size.y / 32):
				for x in int(size.x / 32):
					var pos := start + Vector2i(x, y)
					assert(not terrain_cells.has(pos))
					terrain_cells[pos] = true
		assert(terrain_cells == changes.terrain)
		var scene_history := history.get_history_undo_redo(history.get_object_history_id(stage))
		assert(scene_history.undo())
		assert(Exchange.snapshot(stage) == before)
		assert(stage.get_node("Terrain").get_children() == old_shapes)
		assert(stage.get_children() == old_children)
		assert(scene_history.redo())
		assert(Exchange.snapshot(stage).cells.size() == data.cells.size())
		assert(scene_history.undo())
		print("MAPEDIT PASS ", path)
	plugin.free()
	quit()

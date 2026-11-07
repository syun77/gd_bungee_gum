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
		assert(before.layers.Foods.palette.size() == 11)
		assert(before.layers.Foods.labels.has("ミラノ風ドリア"))
		assert(not before.layers.Foods.labels.has(""))
		assert(before.layers.Baguettes.labels == ["フランスパン"])
		assert(before.layers.MusicNotes.labels == ["音符"])
		var data := before.duplicate(true)
		data.base = Exchange.token(before)
		data = JSON.parse_string(JSON.stringify(data))
		assert(Exchange.validate(stage, before, data) == "")
		var no_op := Exchange.diff(before, data)
		assert(no_op.old.is_empty() and no_op.next.is_empty() and no_op.markers.is_empty())
		assert(no_op.checkpoints_added.is_empty() and no_op.checkpoints_removed.is_empty())
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
		var food_cell := Vector2i(5, 5)
		var foods := stage.get_node("Foods") as TileMapLayer
		assert(foods.get_cell_source_id(food_cell) == -1)
		data.cells.append({"kind": "Foods", "x": 5, "y": 5, "tile": [0, 0, 0, 5]})
		for kind in ["Baguettes", "MusicNotes"]:
			data.cells.append({"kind": kind, "x": 5, "y": 5, "tile": [0, 0, 0, 0]})
		data.markers["PlacementMarkers/PlayerSpawn"][0] += 32
		var checkpoints := stage.get_node("Checkpoints")
		var old_checkpoints := checkpoints.get_children()
		var old_checkpoint := str(stage.get_path_to(old_checkpoints[0]))
		data.markers.erase(old_checkpoint)
		var new_names: Array[String] = []
		var number := 1
		for x in [336.0, 528.0]:
			while checkpoints.has_node("CheckpointMapEdit_%d" % number):
				number += 1
			var checkpoint_name := "CheckpointMapEdit_%d" % number
			new_names.append(checkpoint_name)
			data.markers["Checkpoints/" + checkpoint_name] = [x, 576.0]
			number += 1
		assert(Exchange.validate(stage, before, data) == "")
		var stale := data.duplicate(true)
		stale.base = "stale"
		assert(Exchange.validate(stage, before, stale) == Exchange.STALE)
		var recovered := Exchange.checkpoint_additions_only(before, stale)
		assert(Exchange.validate(stage, before, recovered) == "")
		var recovered_changes := Exchange.diff(before, recovered)
		assert(recovered_changes.old.is_empty() and recovered_changes.next.is_empty())
		assert(recovered_changes.markers.is_empty() and recovered_changes.checkpoints_removed.is_empty())
		assert(recovered_changes.checkpoints_added.size() == 2)
		stale.source = {"cells": before.cells, "markers": before.markers}
		var newer := before.duplicate(true)
		newer.markers["PlacementMarkers/Exit"][1] -= 32.0
		var combined := Exchange.merge_stale(stage, newer, stale)
		assert(combined.has("data"))
		assert(combined.data.markers["PlacementMarkers/Exit"] == newer.markers["PlacementMarkers/Exit"])
		assert(combined.data.markers["PlacementMarkers/PlayerSpawn"] == stale.markers["PlacementMarkers/PlayerSpawn"])
		newer.markers["PlacementMarkers/PlayerSpawn"][0] -= 32.0
		assert(Exchange.merge_stale(stage, newer, stale).has("error"))
		var after_send: Dictionary = combined.data
		var reverted := stale.duplicate(true)
		reverted.source = {"cells": stale.cells, "markers": stale.markers}
		reverted.cells = before.cells
		reverted.markers = before.markers.duplicate(true)
		# Keep the checkpoint set from the applied send. This test reverts tiles and the spawn.
		for marker_path in reverted.markers.keys():
			if marker_path.begins_with("Checkpoints/"):
				reverted.markers.erase(marker_path)
		for marker_path in stale.markers:
			if marker_path.begins_with("Checkpoints/"):
				reverted.markers[marker_path] = stale.markers[marker_path]
		var repeated := Exchange.merge_stale(stage, after_send, reverted)
		assert(repeated.has("data"))
		assert(repeated.data.cells.size() == before.cells.size())
		assert(repeated.data.markers["PlacementMarkers/PlayerSpawn"] == before.markers["PlacementMarkers/PlayerSpawn"])
		assert(repeated.data.markers["PlacementMarkers/Exit"] == newer.markers["PlacementMarkers/Exit"])
		var changes := Exchange.diff(before, data)
		assert(changes.checkpoints_removed == [old_checkpoint] and changes.checkpoints_added.size() == 2)
		assert(changes.terrain_changed)
		var history := plugin.get_undo_redo()
		var old_shapes := stage.get_node("Terrain").get_children()
		var old_children := stage.get_children()
		var decor := stage.get_node_or_null("BackgroundDecor") as TileMapLayer
		var decor_data := decor.tile_map_data if decor else PackedByteArray()
		Exchange.commit(history, stage, changes)
		assert(Exchange.snapshot(stage).cells.size() == data.cells.size())
		assert(foods.get_cell_alternative_tile(food_cell) == 5)
		for kind in ["Baguettes", "MusicNotes"]:
			assert(stage.get_node(kind).get_cell_source_id(food_cell) == 0)
		assert(Exchange.snapshot(stage).markers == data.markers)
		assert(checkpoints.get_child_count() == old_checkpoints.size() + 1)
		for name in new_names:
			var checkpoint := checkpoints.get_node(name)
			assert(checkpoint.owner == stage and checkpoint.has_signal("reached"))
			assert(checkpoint.scene_file_path == "res://scenes/props/checkpoint.tscn")
		var packed := PackedScene.new()
		assert(packed.pack(stage) == OK)
		var copy := packed.instantiate()
		assert(copy.has_node("Checkpoints/" + new_names[1]))
		copy.free()
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
		assert(checkpoints.get_children() == old_checkpoints)
		assert(scene_history.redo())
		assert(Exchange.snapshot(stage).markers == data.markers)
		assert(Exchange.snapshot(stage).cells.size() == data.cells.size())
		assert(foods.get_cell_alternative_tile(food_cell) == 5)
		for kind in ["Baguettes", "MusicNotes"]:
			assert(stage.get_node(kind).get_cell_source_id(food_cell) == 0)
		assert(scene_history.undo())
		print("MAPEDIT PASS ", path)
	plugin.free()
	quit()

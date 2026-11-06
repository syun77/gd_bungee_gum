@tool
extends RefCounted

const LAYERS := ["TerrainTiles", "OneWayPlatforms", "GumAnchors", "GumPassBarriers", "Spikes", "Foods", "MusicNotes"]
const WIDTHS := {
	"res://scenes/stages/time_attack.tscn": 192,
	"res://scenes/stages/theater_stage.tscn": 160,
}
const ATLAS_PALETTES := {
	"TerrainTiles": [[0, 8, 3, 0], [0, 9, 3, 0], [0, 10, 3, 0], [0, 11, 3, 0]],
	"OneWayPlatforms": [[1, 0, 0, 0], [1, 1, 0, 0], [1, 2, 0, 0], [1, 3, 0, 0]],
	"GumAnchors": [[2, 0, 0, 0]],
	"GumPassBarriers": [[3, 0, 0, 0]],
	"Spikes": [[0, 0, 0, 0]],
}
const TILE := 32
const HEIGHT := 24

static func snapshot(stage: Node) -> Dictionary:
	if stage == null or not WIDTHS.has(stage.scene_file_path) or not stage.has_node("Terrain"):
		return {}
	var layers := {}
	var cells: Array = []
	for kind in LAYERS:
		var layer := stage.get_node_or_null(kind) as TileMapLayer
		if layer == null:
			continue
		if layer.tile_set == null or layer.tile_set.tile_size != Vector2i(TILE, TILE):
			return {}
		var palette := {}
		var labels := {}
		for tile: Array in ATLAS_PALETTES.get(kind, []):
			if valid_tile(layer.tile_set, tile):
				palette[str(tile)] = tile
		var used := layer.get_used_cells()
		used.sort()
		for pos in used:
			var tile := [layer.get_cell_source_id(pos), layer.get_cell_atlas_coords(pos).x,
				layer.get_cell_atlas_coords(pos).y, layer.get_cell_alternative_tile(pos)]
			cells.append({"kind": kind, "x": pos.x, "y": pos.y, "tile": tile})
			palette[str(tile)] = tile
		for index in layer.tile_set.get_source_count():
			var id := layer.tile_set.get_source_id(index)
			var source := layer.tile_set.get_source(id) as TileSetScenesCollectionSource
			if source:
				for scene_index in source.get_scene_tiles_count():
					var scene_id := source.get_scene_tile_id(scene_index)
					var tile := [id, 0, 0, scene_id]
					palette[str(tile)] = tile
					var scene := source.get_scene_tile_scene(scene_id)
					if scene:
						labels[str(tile)] = scene.resource_path.get_file().get_basename().capitalize()
		var variants := palette.values()
		variants.sort_custom(func(a: Array, b: Array) -> bool: return str(a) < str(b))
		layers[kind] = {"tileset": layer.tile_set.resource_path, "palette": variants,
			"labels": variants.map(func(tile: Array) -> String: return labels.get(str(tile), ""))}
	if not layers.has("TerrainTiles"):
		return {}
	var markers := {}
	for parent in ["PlacementMarkers", "Checkpoints"]:
		var group := stage.get_node_or_null(parent)
		if group:
			for node in group.get_children():
				if node is Node2D:
					markers[str(stage.get_path_to(node))] = [node.position.x, node.position.y]
	if not markers.has("PlacementMarkers/PlayerSpawn") or not markers.has("PlacementMarkers/Exit"):
		return {}
	return {"version": 1, "stage": stage.scene_file_path, "width": WIDTHS[stage.scene_file_path],
		"height": HEIGHT, "tileSize": TILE, "layers": layers, "cells": cells, "markers": markers}

static func token(data: Dictionary) -> String:
	return JSON.stringify(data, "", true, true).sha256_text()

static func integer(value: Variant, lower: int, upper: int) -> bool:
	return (value is int or value is float) and value >= lower and value <= upper and value == floor(value)

static func index_cells(cells: Array) -> Dictionary:
	var result := {}
	for cell in cells:
		result[cell.kind + "/" + str(Vector2i(cell.x, cell.y))] = {
			"kind": cell.kind, "x": int(cell.x), "y": int(cell.y),
			"tile": cell.tile.map(func(v: Variant) -> int: return int(v)),
		}
	return result

static func validate(stage: Node, before: Dictionary, data: Variant) -> String:
	if before.is_empty() or not data is Dictionary:
		return "Open a supported stage and paste a MapEdit JSON document."
	for key in ["version", "stage", "width", "height", "tileSize"]:
		if data.get(key) != before[key]:
			return "The document version, stage or grid does not match."
	if data.get("base") != token(before):
		return "Godot placements have changed. Copy the stage again before editing."
	if not data.get("cells") is Array or not data.get("markers") is Dictionary or not data.get("layers") is Dictionary:
		return "Missing layers, cells or markers."
	if data.layers.size() != before.layers.size():
		return "Layer set does not match the stage."
	for kind in before.layers:
		var info: Variant = data.layers.get(kind)
		if not info is Dictionary or info.get("tileset") != before.layers[kind].tileset:
			return "TileSet does not match: " + kind
	if data.cells.size() > before.width * HEIGHT * before.layers.size():
		return "Too many cells."
	for cell in data.cells:
		if not cell is Dictionary or not cell.get("kind") is String or not before.layers.has(cell.kind):
			return "Unknown tile layer."
		if not integer(cell.get("x"), 0, before.width - 1) or not integer(cell.get("y"), 0, HEIGHT - 1):
			return "Cell outside the stage."
		var tile: Variant = cell.get("tile")
		if not tile is Array or tile.size() != 4 or not tile.all(func(v: Variant) -> bool: return integer(v, 0, 2147483647)):
			return "Malformed tile reference."
		var layer := stage.get_node(NodePath(cell.kind)) as TileMapLayer
		if not valid_tile(layer.tile_set, tile):
			return "Unknown tile variant."
		if not before.layers[cell.kind].palette.has(tile.map(func(v: Variant) -> int: return int(v))):
			return "Tile variant is outside the layer palette."
	if index_cells(data.cells).size() != data.cells.size():
		return "Duplicate tile in one layer."
	if data.markers.size() != before.markers.size():
		return "Marker set does not match the stage."
	for path in before.markers:
		var pos: Variant = data.markers.get(path)
		if not pos is Array or pos.size() != 2:
			return "Missing marker: " + path
		for axis in 2:
			var limit: int = (before.width if axis == 0 else HEIGHT) * TILE
			if not (pos[axis] is int or pos[axis] is float) or not is_finite(pos[axis]) or pos[axis] < 0 or pos[axis] > limit:
				return "Marker outside the stage: " + path
	return ""

static func valid_tile(tileset: TileSet, tile: Array) -> bool:
	var id := int(tile[0])
	if not tileset.has_source(id):
		return false
	var source := tileset.get_source(id)
	var atlas := Vector2i(tile[1], tile[2])
	var alternative := int(tile[3])
	if source is TileSetAtlasSource:
		# The high bits encode Godot's flip and transpose flags.
		alternative &= 4095
	return source.has_tile(atlas) and source.has_alternative_tile(atlas, alternative)

static func diff(before: Dictionary, after: Dictionary) -> Dictionary:
	var old := index_cells(before.cells)
	var next := index_cells(after.cells)
	var removed := {}
	var placed := {}
	var markers := {}
	var terrain_changed := false
	for key in old:
		if not next.has(key) or old[key].tile != next[key].tile:
			removed[key] = old[key]
			terrain_changed = terrain_changed or (old[key].kind == "TerrainTiles" and not next.has(key))
	for key in next:
		if not old.has(key) or old[key].tile != next[key].tile:
			placed[key] = next[key]
			terrain_changed = terrain_changed or (next[key].kind == "TerrainTiles" and not old.has(key))
	for path in before.markers:
		if before.markers[path] != after.markers[path]:
			markers[path] = [Vector2(before.markers[path][0], before.markers[path][1]),
				Vector2(after.markers[path][0], after.markers[path][1])]
	var terrain := {}
	if terrain_changed:
		for cell: Dictionary in next.values():
			if cell.kind == "TerrainTiles":
				terrain[Vector2i(cell.x, cell.y)] = true
	return {"old": removed, "next": placed, "markers": markers,
		"terrain_changed": terrain_changed, "terrain": terrain}

static func commit(history: EditorUndoRedoManager, stage: Node, changes: Dictionary) -> void:
	history.create_action("Apply MapEdit placements", UndoRedo.MERGE_DISABLE, stage, true)
	var keys: Dictionary = changes.old.duplicate()
	keys.merge(changes.next)
	for key in keys:
		var cell: Dictionary = keys[key]
		var layer := stage.get_node(NodePath(cell.kind)) as TileMapLayer
		var point := Vector2i(cell.x, cell.y)
		var old: Dictionary = changes.old.get(key, {})
		var next: Dictionary = changes.next.get(key, {})
		var previous_tile: Array = old.get("tile", [-1, -1, -1, -1])
		var next_tile: Array = next.get("tile", [-1, -1, -1, -1])
		history.add_do_method(layer, "set_cell", point, next_tile[0],
			Vector2i(next_tile[1], next_tile[2]), next_tile[3])
		history.add_undo_method(layer, "set_cell", point, previous_tile[0],
			Vector2i(previous_tile[1], previous_tile[2]), previous_tile[3])
	for path in changes.markers:
		var marker := stage.get_node(NodePath(path)) as Node2D
		history.add_do_property(marker, "position", changes.markers[path][1])
		history.add_undo_property(marker, "position", changes.markers[path][0])
	if changes.terrain_changed:
		sync_terrain(history, stage, changes.terrain)
	history.commit_action()

static func rectangles(cells: Dictionary) -> Array[Rect2i]:
	var remaining := cells.duplicate()
	var ordered := remaining.keys()
	ordered.sort()
	var result: Array[Rect2i] = []
	for origin: Vector2i in ordered:
		if not remaining.has(origin):
			continue
		var width := 1
		while remaining.has(origin + Vector2i(width, 0)):
			width += 1
		var height := 1
		while row_exists(remaining, origin + Vector2i(0, height), width):
			height += 1
		result.append(Rect2i(origin, Vector2i(width, height)))
		for y in height:
			for x in width:
				remaining.erase(origin + Vector2i(x, y))
	return result

static func row_exists(cells: Dictionary, origin: Vector2i, width: int) -> bool:
	for x in width:
		if not cells.has(origin + Vector2i(x, 0)):
			return false
	return true

static func sync_terrain(history: EditorUndoRedoManager, stage: Node, cells: Dictionary) -> void:
	var body := stage.get_node("Terrain")
	var shapes := body.get_children()
	shapes.reverse()
	for child in shapes:
		if child is CollisionShape2D:
			remove_derived(history, body, child, stage)
	var has_rim := stage.scene_file_path.ends_with("/theater_stage.tscn")
	if has_rim:
		var children := stage.get_children()
		children.reverse()
		for child in children:
			if child is Line2D and str(child.name).begins_with("Rim"):
				remove_derived(history, stage, child, stage)
	var rects := rectangles(cells)
	for index in rects.size():
		var rect := rects[index]
		var shape := CollisionShape2D.new()
		shape.name = "Surface%02d" % index
		var box := RectangleShape2D.new()
		box.size = Vector2(rect.size * TILE)
		shape.shape = box
		var origin := Vector2(rect.position * TILE)
		shape.position = origin + box.size / 2
		add_derived(history, body, shape, stage)
		if has_rim:
			var rim := Line2D.new()
			rim.name = "Rim%02d" % index
			rim.points = PackedVector2Array([origin, origin + Vector2(box.size.x, 0),
				origin + box.size, origin + Vector2(0, box.size.y), origin])
			rim.width = 2
			rim.default_color = Color("795747")
			add_derived(history, stage, rim, stage)

static func remove_derived(history: EditorUndoRedoManager, parent: Node, child: Node, stage: Node) -> void:
	history.add_do_method(parent, "remove_child", child)
	history.add_undo_method(parent, "move_child", child, child.get_index())
	history.add_undo_property(child, "owner", stage)
	history.add_undo_method(parent, "add_child", child)
	history.add_undo_reference(child)

static func add_derived(history: EditorUndoRedoManager, parent: Node, child: Node, stage: Node) -> void:
	history.add_do_method(parent, "add_child", child)
	history.add_do_property(child, "owner", stage)
	history.add_do_reference(child)
	history.add_undo_method(parent, "remove_child", child)

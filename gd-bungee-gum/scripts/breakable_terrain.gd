extends RefCounted
## Runtime edits stay in the instantiated stage; scene reload restores authored tiles.
const Rectangles = preload("res://scripts/terrain_rectangles.gd")
const BRICK_SOURCE := 4
const BreakEffect = preload("res://scripts/brick_break_effect.gd")

static func destroy_hit(hit: Dictionary) -> bool:
	if hit.is_empty():
		return false
	var body = hit.collider
	if not body is StaticBody2D or body.name != "Terrain":
		return false
	var stage: Node = body.get_parent()
	var layer := stage.get_node_or_null("TerrainTiles") as TileMapLayer
	if layer == null:
		return false
	var cell := layer.local_to_map(layer.to_local(hit.position - hit.normal * 0.1))
	if layer.get_cell_source_id(cell) != BRICK_SOURCE or layer.get_cell_atlas_coords(cell) != Vector2i.ZERO:
		return false
	var center := layer.to_global(layer.map_to_local(cell))
	layer.erase_cell(cell)
	_rebuild(stage, body, layer)
	var effect := BreakEffect.new()
	stage.add_child(effect)
	effect.global_position = center
	return true

static func _rebuild(stage: Node, body: StaticBody2D, layer: TileMapLayer) -> void:
	for child in body.get_children():
		if child is CollisionShape2D:
			body.remove_child(child)
			child.free()
	var has_rim := stage.scene_file_path.ends_with("/theater_stage.tscn")
	if has_rim:
		for child in stage.get_children():
			if child is Line2D and str(child.name).begins_with("Rim"):
				stage.remove_child(child)
				child.free()
	var cells := {}
	for cell in layer.get_used_cells():
		cells[cell] = true
	var tile := layer.tile_set.tile_size
	for rect in Rectangles.rectangles(cells):
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(rect.size * tile)
		shape.shape = box
		# TileMap coordinates are cell-centered; use transforms for terrain-local geometry.
		var center := layer.map_to_local(rect.position) + Vector2((rect.size - Vector2i.ONE) * tile) / 2
		shape.transform = body.global_transform.affine_inverse() * layer.global_transform
		shape.position = body.to_local(layer.to_global(center))
		body.add_child(shape)
		if has_rim:
			var rim := Line2D.new()
			rim.name = "RimRuntime%d" % body.get_child_count()
			var half := box.size / 2
			for corner in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y), -half]:
				rim.add_point(stage.to_local(body.to_global(shape.transform * corner)))
			rim.width = 2
			rim.default_color = Color("795747")
			stage.add_child(rim)

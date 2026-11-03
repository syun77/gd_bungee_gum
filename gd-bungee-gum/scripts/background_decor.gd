extends RefCounted
## Collision-free editor-paintable scenery, shared by stage authoring tools.
const Layout = preload("res://scripts/stage_layout.gd")
const TILESET = preload("res://assets/tilesets/background_decor_tileset.tres")

static func create_layer() -> TileMapLayer:
	var decor := TileMapLayer.new()
	decor.name = "BackgroundDecor"
	decor.tile_set = TILESET
	decor.collision_enabled = false
	decor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	decor.modulate = Color(0.82, 0.86, 0.84, 0.85)
	for placement in Layout.BACKGROUND_DECOR:
		decor.set_cell(Vector2i(placement.x, placement.y), 0, atlas_coords(placement.z))
	return decor

static func atlas_coords(id: int) -> Vector2i:
	return Vector2i((id % 4) * 3, (id / 4) * 3)

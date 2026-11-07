extends RefCounted

const TILESET = preload("res://assets/items/baguette_tileset.tres")
const THEATER_STAGE := [Vector2i(6, 18), Vector2i(32, 20), Vector2i(82, 20)]
const STAGE_2 := [Vector2i(7, 20), Vector2i(14, 18), Vector2i(34, 20)]
const STAGE_3 := [Vector2i(7, 20), Vector2i(13, 20), Vector2i(34, 16)]

static func create_layer(cells: Array) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = "Baguettes"
	layer.tile_set = TILESET
	# Scene tiles are centered by Godot; put the pickup origin on the bottom of its cell.
	layer.position.y = 16
	layer.collision_enabled = false
	for cell in cells:
		layer.set_cell(cell, 0, Vector2i.ZERO, 0)
	return layer

extends RefCounted
## Route cues on the 32px grid. Gaps separate ground runs from upward gum lifts.
const TILESET = preload("res://assets/items/music_note_tileset.tres")
const RESTAURANT := [
	# Contact: cross the low hazard, then rise beside the first exit ledge.
	Vector2i(5, 18), Vector2i(7, 16), Vector2i(11, 16), Vector2i(12, 18),
	Vector2i(14, 18), Vector2i(16, 18), Vector2i(18, 17), Vector2i(18, 15),
	Vector2i(21, 14), Vector2i(25, 14),
	# Swing basin and the two-step recovery climb.
	Vector2i(27, 18), Vector2i(29, 19), Vector2i(31, 20), Vector2i(33, 19),
	Vector2i(35, 18), Vector2i(36, 16), Vector2i(40, 20), Vector2i(42, 20),
	Vector2i(44, 20), Vector2i(46, 19), Vector2i(47, 17), Vector2i(47, 14),
	Vector2i(49, 14), Vector2i(53, 14),
	# Cargo workspace; climb at the right-hand pair of one-way shelves.
	Vector2i(55, 18), Vector2i(59, 18), Vector2i(61, 18), Vector2i(64, 17),
	Vector2i(66, 18), Vector2i(69, 18), Vector2i(71, 15),
	Vector2i(73, 12), Vector2i(77, 12),
	# Heavy-anchor basin: keep the cues below the upper optional route.
	Vector2i(81, 18), Vector2i(84, 20), Vector2i(85, 20), Vector2i(87, 19),
	Vector2i(89, 18), Vector2i(92, 20), Vector2i(94, 20), Vector2i(97, 20),
	Vector2i(98, 19), Vector2i(98, 15), Vector2i(99, 14),
	Vector2i(101, 14), Vector2i(105, 14),
	# Low cover and the exit lift.
	Vector2i(107, 17), Vector2i(108, 16), Vector2i(112, 16), Vector2i(116, 16),
	Vector2i(117, 18), Vector2i(119, 17), Vector2i(122, 18), Vector2i(122, 17),
	Vector2i(123, 14), Vector2i(125, 14), Vector2i(129, 14),
	# Final basin, recovery shelves and the last upward shot to the door.
	Vector2i(133, 19), Vector2i(135, 19), Vector2i(137, 19), Vector2i(139, 19),
	Vector2i(142, 20), Vector2i(144, 20), Vector2i(144, 19), Vector2i(145, 14),
	Vector2i(149, 14), Vector2i(149, 13), Vector2i(150, 10), Vector2i(151, 10),
	Vector2i(152, 10),
]
const TERRACE := [
	Vector2i(6, 20), Vector2i(8, 18), Vector2i(10, 18), Vector2i(12, 18),
	Vector2i(15, 18), Vector2i(17, 18), Vector2i(20, 20), Vector2i(22, 20),
	Vector2i(22, 18), Vector2i(23, 16), Vector2i(25, 16), Vector2i(28, 16),
	Vector2i(31, 18), Vector2i(33, 20), Vector2i(35, 20), Vector2i(35, 18),
	Vector2i(37, 18), Vector2i(40, 18), Vector2i(44, 20), Vector2i(46, 20),
	Vector2i(46, 18), Vector2i(47, 16), Vector2i(52, 16),
	Vector2i(55, 18), Vector2i(59, 20),
]
const KITCHEN := [
	Vector2i(6, 20), Vector2i(8, 18), Vector2i(10, 18), Vector2i(12, 20),
	Vector2i(15, 18), Vector2i(17, 18), Vector2i(20, 18),
	Vector2i(23, 20), Vector2i(25, 20), Vector2i(28, 18), Vector2i(30, 20),
	Vector2i(30, 18), Vector2i(31, 16), Vector2i(33, 16), Vector2i(37, 16),
	Vector2i(39, 18), Vector2i(45, 18),
	Vector2i(47, 18), Vector2i(50, 18), Vector2i(53, 20), Vector2i(54, 20),
	Vector2i(58, 20),
]

static func create_layer(cells: Array) -> TileMapLayer:
	var notes := TileMapLayer.new()
	notes.name = "MusicNotes"
	notes.tile_set = TILESET
	notes.collision_enabled = false
	notes.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	notes.z_index = 3
	for cell in cells:
		notes.set_cell(cell, 0, Vector2i.ZERO, 0)
	return notes

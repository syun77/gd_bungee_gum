extends SceneTree
## Run from the project root: Godot --headless --path . --script res://tools/build_theater_stage.gd
## Rebuilds the authored scene and TileSet; manual scene edits will be overwritten.

const TILE := 32
const STAGE_PATH := "res://scenes/stages/theater_stage.tscn"
const TILESET_PATH := "res://assets/tilesets/theater_tileset.tres"
const TERRAIN := [
	# Left wall, upper boundary, right wall.
	Rect2i(0, 2, 2, 22), Rect2i(2, 2, 156, 2), Rect2i(158, 2, 2, 22),
	# 01: contact kick-off; open landing and raised step.
	Rect2i(2, 20, 16, 4), Rect2i(18, 17, 7, 7),
	# 02: ceiling swing; two recovery shelves over the open pit.
	Rect2i(25, 8, 21, 2), Rect2i(29, 22, 5, 2), Rect2i(39, 20, 5, 4),
	Rect2i(46, 17, 9, 7),
	# 03: cargo manipulation; broad working floor and a high ledge.
	Rect2i(55, 20, 17, 4), Rect2i(72, 16, 8, 8), Rect2i(59, 7, 15, 2),
	# 04: heavy anchor; supported upper shelf and deep crossing.
	Rect2i(80, 18, 6, 6), Rect2i(86, 10, 7, 2), Rect2i(96, 21, 4, 3),
	Rect2i(103, 16, 6, 8),
	# 05: projectile corridor; level working floor, cover and overhead surfaces.
	Rect2i(109, 20, 23, 4), Rect2i(117, 17, 2, 3), Rect2i(125, 16, 2, 4),
	Rect2i(112, 7, 18, 2),
	# 06: final climb and exit landing.
	Rect2i(132, 18, 6, 6), Rect2i(141, 15, 5, 2), Rect2i(150, 12, 8, 12),
	Rect2i(136, 8, 9, 2),
]
const SECTION_NAMES := ["01 / CONTACT", "02 / SWING", "03 / LIGHT CARGO", "04 / HEAVY ANCHOR", "05 / REDIRECT", "06 / EXIT"]
var stage: Node2D
var tiles: TileSet

func _initialize() -> void:
	tiles = TileSet.new()
	tiles.tile_size = Vector2i(TILE, TILE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/tilesets/theater_tileset.png")
	atlas.texture_region_size = Vector2i(TILE, TILE)
	for id in range(105):
		atlas.create_tile(Vector2i(id % 16, id / 16))
	tiles.add_source(atlas, 0)
	assert(ResourceSaver.save(tiles, TILESET_PATH) == OK)
	tiles = load(TILESET_PATH)
	stage = Node2D.new()
	stage.name = "TheaterStage"
	stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var background := layer("Background", Color(0.65, 0.78, 0.72, 0.45))
	for x in range(2, 158):
		for y in range(4, 24):
			# Sparse masonry piers, with open dark bays for readable silhouettes.
			if x % 26 < 3 or y >= 22:
				put(background, x, y, 79 + (x + y) % 2)
	var iron := layer("BackgroundIron", Color(0.8, 0.9, 0.82, 0.6))
	for x in range(2, 158):
		put(iron, x, 5, 66)
	var terrain := layer("TerrainTiles")
	var body := StaticBody2D.new()
	body.name = "Terrain"
	body.collision_layer = 1
	body.collision_mask = 0
	add(stage, body)
	for i in range(TERRAIN.size()):
		var rect: Rect2i = TERRAIN[i]
		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y):
				put(terrain, x, y, 56 + (x * 7 + y * 3) % 4)
		var shape := CollisionShape2D.new()
		shape.name = "Surface%02d" % i
		var box := RectangleShape2D.new()
		box.size = Vector2(rect.size * TILE)
		shape.shape = box
		shape.position = Vector2(rect.position * TILE) + box.size / 2
		add(body, shape)
		# Continuous rim keeps the physical silhouette legible despite atlas seams.
		var rim := Line2D.new()
		rim.name = "Rim%02d" % i
		var p := Vector2(rect.position * TILE)
		var s := box.size
		rim.points = PackedVector2Array([p, p + Vector2(s.x, 0), p + s, p + Vector2(0, s.y), p])
		rim.width = 2
		rim.default_color = Color("795747")
		add(stage, rim)
	var signs := layer("Signs")
	for section in range(6):
		var x := 4 + section * 26
		put(signs, x, 12, 98)
		label(SECTION_NAMES[section], Vector2(x * TILE, 192), 18, Color("fff0cc"))
	put(signs, 5, 18, 99)
	put(signs, 154, 10, 100)
	for x in [25, 35, 86, 94, 138, 147]:
		put(signs, x, 23, 102)
	var markers := Node2D.new()
	markers.name = "PlacementMarkers"
	add(stage, markers)
	marker(markers, "PlayerSpawn", Vector2(160, 620))
	marker(markers, "LightBoxSpawn", Vector2(2048, 616))
	marker(markers, "HeavyBoxSpawn", Vector2(2864, 296))
	marker(markers, "ProjectileEmitter", Vector2(3584, 592))
	marker(markers, "ProjectileTarget", Vector2(4096, 480))
	marker(markers, "Exit", Vector2(4944, 364))
	for section in range(6):
		marker(markers, "Section%02d" % (section + 1), Vector2((4 + section * 26) * TILE, 384))
	label("ENTRANCE", Vector2(96, 552), 14, Color("fff0cc"))
	label("EXIT", Vector2(4896, 284), 20, Color("fff0cc"))
	var scene := PackedScene.new()
	assert(scene.pack(stage) == OK)
	assert(ResourceSaver.save(scene, STAGE_PATH) == OK)
	print("Saved theater stage: ", terrain.get_used_cells().size(), " terrain cells, ", TERRAIN.size(), " collision rectangles.")
	stage.free()
	quit()

func add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = stage

func layer(node_name: String, tint := Color.WHITE) -> TileMapLayer:
	var result := TileMapLayer.new()
	result.name = node_name
	result.tile_set = tiles
	result.modulate = tint
	result.collision_enabled = false
	add(stage, result)
	return result

func put(target: TileMapLayer, x: int, y: int, id: int) -> void:
	target.set_cell(Vector2i(x, y), 0, Vector2i(id % 16, id / 16))

func label(value: String, position: Vector2, size: int, color: Color) -> void:
	var result := Label.new()
	result.text = value
	result.position = position
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	add(stage, result)

func marker(parent: Node, node_name: String, position: Vector2) -> void:
	var result := Marker2D.new()
	result.name = node_name
	result.position = position
	add(parent, result)

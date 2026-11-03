extends SceneTree
## Run from the project root: Godot --headless --path . --script res://tools/build_theater_stage.gd
## Rebuilds the authored scene and TileSet; manual scene edits will be overwritten.

const Layout = preload("res://scripts/stage_layout.gd")
const TILE := Layout.TILE
const STAGE_PATH := "res://scenes/stages/theater_stage.tscn"
const TILESET_PATH := "res://assets/tilesets/theater_tileset.tres"
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
	add_one_way_source(tiles)
	add_gum_anchor_source(tiles)
	assert(ResourceSaver.save(tiles, TILESET_PATH) == OK)
	tiles = load(TILESET_PATH)
	stage = Node2D.new()
	stage.name = "TheaterStage"
	stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var background := layer("Background", Color(0.65, 0.78, 0.72, 0.45))
	for x in range(2, Layout.SIZE.x - 2):
		for y in range(4, Layout.SIZE.y):
			# Sparse masonry piers, with open dark bays for readable silhouettes.
			if x % 26 < 3 or y >= 22:
				put(background, x, y, 79 + (x + y) % 2)
	var iron := layer("BackgroundIron", Color(0.8, 0.9, 0.82, 0.6))
	for x in range(2, Layout.SIZE.x - 2):
		put(iron, x, 5, 66)
	var terrain := layer("TerrainTiles")
	var body := StaticBody2D.new()
	body.name = "Terrain"
	body.collision_layer = 1
	body.collision_mask = 0
	add(stage, body)
	for i in range(Layout.TERRAIN.size()):
		var rect: Rect2i = Layout.TERRAIN[i]
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
	add_one_way_layer()
	var anchors := layer("GumAnchors")
	anchors.physics_quadrant_size = 1
	anchors.collision_enabled = true
	for cell in Layout.GUM_ANCHORS:
		anchors.set_cell(cell, 2, Vector2i.ZERO)
	var foods := layer("Foods")
	foods.tile_set = load("res://assets/foods/food_tileset.tres")
	foods.z_index = 3
	for food in Layout.FOODS:
		foods.set_cell(Vector2i(food.x, food.y), 0, Vector2i.ZERO, food.z)
	var signs := layer("Signs")
	for section in Layout.SECTION_NAMES.size():
		var x := 4 + section * 26
		put(signs, x, 12, 98)
		label(Layout.SECTION_NAMES[section], Vector2(x * TILE, 192), Color("fff0cc"))
	put(signs, 5, 18, 99)
	put(signs, 154, 10, 100)
	var markers := Node2D.new()
	markers.name = "PlacementMarkers"
	add(stage, markers)
	for marker_name in Layout.MARKERS:
		marker(markers, marker_name, Layout.MARKERS[marker_name])
	for section in Layout.SECTION_NAMES.size():
		marker(markers, "Section%02d" % (section + 1), Layout.SECTION_STARTS[section])
	label("ENTRANCE", Vector2(96, 552), Color("fff0cc"))
	label("EXIT", Vector2(4896, 292), Color("fff0cc"))
	var scene := PackedScene.new()
	assert(scene.pack(stage) == OK)
	assert(ResourceSaver.save(scene, STAGE_PATH) == OK)
	print("Saved theater stage: ", terrain.get_used_cells().size(), " terrain cells, ", Layout.TERRAIN.size(), " collision rectangles.")
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

func label(value: String, position: Vector2, color: Color) -> void:
	var result := Label.new()
	result.text = value
	result.position = position
	result.add_theme_color_override("font_color", color)
	add(stage, result)

func marker(parent: Node, node_name: String, position: Vector2) -> void:
	var result := Marker2D.new()
	result.name = node_name
	result.position = position
	add(parent, result)

func add_one_way_source(target: TileSet) -> void:
	target.add_physics_layer()
	target.set_physics_layer_collision_layer(0, 8)
	target.set_physics_layer_collision_mask(0, 0)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/tilesets/restaurant_one_way_platform.png")
	atlas.texture_region_size = Vector2i(TILE, TILE)
	target.add_source(atlas, 1)
	for x in 4:
		var cell := Vector2i(x, 0)
		atlas.create_tile(cell)
		var data := atlas.get_tile_data(cell, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, PackedVector2Array([
			Vector2(-16, -16), Vector2(16, -16), Vector2(16, -11), Vector2(-16, -11)]))
		data.set_collision_polygon_one_way(0, 0, true)
		data.set_collision_polygon_one_way_margin(0, 0, 1.0)

func add_one_way_layer() -> void:
	var platforms := layer("OneWayPlatforms")
	platforms.collision_enabled = true
	for rect in Layout.ONE_WAY_FLOORS:
		for offset in rect.size.x:
			var tile := 1
			if rect.size.x == 1:
				tile = 3
			elif offset == 0:
				tile = 0
			elif offset == rect.size.x - 1:
				tile = 2
			platforms.set_cell(rect.position + Vector2i(offset, 0), 1, Vector2i(tile, 0))

func add_gum_anchor_source(target: TileSet) -> void:
	target.add_physics_layer()
	target.set_physics_layer_collision_layer(1, 16)
	target.set_physics_layer_collision_mask(1, 0)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/tilesets/restaurant_gum_anchor.png")
	atlas.texture_region_size = Vector2i(TILE, TILE)
	target.add_source(atlas, 2)
	atlas.create_tile(Vector2i.ZERO)
	var data := atlas.get_tile_data(Vector2i.ZERO, 0)
	# Filled target includes the hole so aiming through the ring center attaches.
	data.add_collision_polygon(1)
	data.set_collision_polygon_points(1, 0, PackedVector2Array(Layout.GUM_ANCHOR_POLYGON))

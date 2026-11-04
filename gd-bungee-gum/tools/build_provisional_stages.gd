extends SceneTree
## Rebuild only stage2/3 scenes; shared TileSet and original restaurant are untouched.
var stage: Node2D
var tiles := preload("res://assets/tilesets/theater_tileset.tres")

func _initialize() -> void:
	for number in [2, 3]:
		build(number)
	quit()

func add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = stage

func layer(title: String, set: TileSet, collision := false) -> TileMapLayer:
	var result := TileMapLayer.new()
	result.name = title
	result.tile_set = set
	result.collision_enabled = collision
	add(stage, result)
	return result

func build(number: int) -> void:
	stage = Node2D.new()
	stage.name = "TheaterStage"
	stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2.ZERO, Vector2(2048, 0), Vector2(2048, 768), Vector2(0, 768)])
	background.color = Color("526d70") if number == 2 else Color("665f67")
	background.z_index = -10
	add(stage, background)
	var terrain := layer("TerrainTiles", tiles)
	var body := StaticBody2D.new()
	body.name = "Terrain"
	body.collision_layer = 1
	body.collision_mask = 0
	add(stage, body)
	# Continuous recovery floor,64px steps; rings are within the saved160px shot range.
	var rects := [Rect2i(0, 0, 2, 24), Rect2i(62, 0, 2, 24), Rect2i(2, 22, 60, 2)]
	if number == 2:
		rects.append_array([Rect2i(12, 20, 6, 2), Rect2i(24, 18, 6, 4), Rect2i(36, 20, 6, 2), Rect2i(48, 18, 6, 4)])
	else:
		rects.append_array([Rect2i(16, 20, 6, 2), Rect2i(32, 18, 6, 4), Rect2i(46, 20, 6, 2)])
	for rect in rects:
		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y):
				terrain.set_cell(Vector2i(x, y), 0, Vector2i(8 + posmod(x + y, 4), 3))
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(rect.size * 32)
		shape.shape = box
		shape.position = Vector2(rect.position * 32) + box.size / 2
		add(body, shape)
		var rim := Line2D.new()
		var p := Vector2(rect.position * 32)
		var s := box.size
		rim.points = PackedVector2Array([p, p + Vector2(s.x, 0), p + s, p + Vector2(0, s.y), p])
		rim.default_color = Color("e9c9ab")
		rim.width = 2
		add(stage, rim)
	var anchors := layer("GumAnchors", tiles, true)
	anchors.physics_quadrant_size = 1
	var cells := [Vector2i(10, 17), Vector2i(15, 15), Vector2i(22, 15), Vector2i(27, 13), Vector2i(34, 17), Vector2i(39, 15), Vector2i(46, 15), Vector2i(51, 13), Vector2i(57, 17)]
	for cell in cells:
		anchors.set_cell(cell, 2, Vector2i.ZERO)
	var platforms := layer("OneWayPlatforms", tiles, true)
	for x in range(7, 10):
		platforms.set_cell(Vector2i(x, 20), 1, Vector2i(1, 0))
	var foods := layer("Foods", load("res://assets/foods/food_tileset.tres"))
	for i in range(8):
		foods.set_cell(Vector2i(7 + i * 7, 16 if i % 2 == 0 else 20), 0, Vector2i.ZERO, (i + number) % 11)
	var checkpoints := Node2D.new()
	checkpoints.name = "Checkpoints"
	add(stage, checkpoints)
	var checkpoint := preload("res://scenes/props/checkpoint.tscn").instantiate()
	checkpoint.name = "Checkpoint01"
	checkpoint.position = Vector2(960, 704)
	add(checkpoints, checkpoint)
	var markers := Node2D.new()
	markers.name = "PlacementMarkers"
	add(stage, markers)
	var positions := {"PlayerSpawn": Vector2(160, 702), "LightBoxSpawn": Vector2(440, 682), "HeavyBoxSpawn": Vector2(1380, 682), "EntranceLightBox": Vector2(760, 682), "EntranceHeavyBox": Vector2(1800, 682), "PulleySpawn": Vector2(1088 if number == 2 else 736, 540), "Exit": Vector2(1904, 704)}
	for title in positions:
		var marker := Marker2D.new()
		marker.name = title
		marker.position = positions[title]
		add(markers, marker)
	for entry in [{"text": "STAGE %02d" % number, "position": Vector2(96, 440)}, {"text": "GOAL", "position": Vector2(1840, 600)}]:
		var label := Label.new()
		label.text = entry.text
		label.position = entry.position
		label.modulate = Color("fff0cc")
		add(stage, label)
	var packed := PackedScene.new()
	assert(packed.pack(stage) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/stages/stage_%d.tscn" % number) == OK)
	stage.free()

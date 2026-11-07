extends SceneTree
## Rebuild the dedicated Time Attack map.
const BaguetteLayout = preload("res://scripts/baguette_layout.gd")
const NoteLayout = preload("res://scripts/music_note_layout.gd")

var stage: Node2D
var tiles := preload("res://assets/tilesets/theater_tileset.tres")

func _initialize() -> void:
	build()
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

func build() -> void:
	stage = Node2D.new()
	stage.name = "TheaterStage"
	stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2.ZERO, Vector2(2048, 0), Vector2(2048, 768), Vector2(0, 768)])
	background.color = Color("526d70")
	background.z_index = -10
	add(stage, background)
	var terrain := layer("TerrainTiles", tiles)
	var terrain_material := ShaderMaterial.new()
	terrain_material.shader = preload("res://shaders/time_attack_terrain.gdshader")
	terrain.material = terrain_material
	layer("OneWayPlatforms", tiles, true)
	var body := StaticBody2D.new()
	body.name = "Terrain"
	body.collision_layer = 1
	body.collision_mask = 0
	add(stage, body)
	# A continuous recovery floor below the raised route.
	var rects := [
		Rect2i(0, 0, 2, 24), Rect2i(62, 0, 2, 24), Rect2i(2, 22, 60, 2),
		Rect2i(12, 19, 7, 3), Rect2i(19, 16, 7, 6), Rect2i(26, 13, 5, 9),
		Rect2i(31, 15, 3, 7), Rect2i(34, 17, 3, 5), Rect2i(37, 19, 3, 3),
		Rect2i(44, 20, 3, 2), Rect2i(47, 18, 15, 4),
	]
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
	var anchors := layer("GumAnchors", tiles, true)
	anchors.physics_quadrant_size = 1
	for cell in [Vector2i(11, 18), Vector2i(18, 15), Vector2i(25, 12),
			Vector2i(38, 15), Vector2i(43, 17), Vector2i(49, 15)]:
		anchors.set_cell(cell, 2, Vector2i.ZERO)
	var spikes := layer("Spikes", preload("res://assets/hazards/spike_tileset.tres"))
	spikes.z_index = 3
	layer("GumBoxes", preload("res://assets/props/gum_box_tileset.tres"))
	var foods := layer("Foods", preload("res://assets/foods/food_tileset.tres"))
	foods.z_index = 3
	add(stage, BaguetteLayout.create_layer([]))
	add(stage, NoteLayout.create_layer([]))
	var markers := Node2D.new()
	markers.name = "PlacementMarkers"
	add(stage, markers)
	for entry in [[&"PlayerSpawn", Vector2(160, 702)], [&"Exit", Vector2(1856, 574)]]:
		var marker := Marker2D.new()
		marker.name = entry[0]
		marker.position = entry[1]
		add(markers, marker)
	for entry in [["SERVICE ENTRANCE", Vector2(96, 510)], ["ATRIUM", Vector2(560, 330)],
			["TERRACE", Vector2(1110, 365)], ["GOAL", Vector2(1770, 470)]]:
		var label := Label.new()
		label.text = entry[0]
		label.position = entry[1]
		label.modulate = Color("fff0cc")
		add(stage, label)
	var packed := PackedScene.new()
	assert(packed.pack(stage) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/stages/time_attack.tscn") == OK)
	stage.free()

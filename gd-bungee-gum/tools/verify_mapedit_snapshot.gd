extends SceneTree
const Exchange = preload("res://addons/mapedit/stage_exchange.gd")

func _initialize() -> void:
	for path in Exchange.WIDTHS:
		var stage := (load(path) as PackedScene).instantiate()
		assert(Exchange.snapshot_error(stage) == "")
		var before := Exchange.snapshot(stage)
		assert(not before.is_empty())
		var data := before.duplicate(true)
		data.base = Exchange.token(before)
		assert(Exchange.validate(stage, before, JSON.parse_string(JSON.stringify(data))) == "")
		var terrain := stage.get_node("TerrainTiles")
		terrain.name = "　"
		assert(Exchange.snapshot(stage).is_empty())
		assert(Exchange.snapshot_error(stage).contains("TerrainTiles"))
		assert(Exchange.validate(stage, {}, data).contains("TerrainTiles"))
		terrain.name = "TerrainTiles"
		assert(Exchange.snapshot(stage) == before)
		var layer := terrain as TileMapLayer
		var tiles := layer.tile_set
		layer.tile_set = null
		assert(Exchange.snapshot_error(stage).contains("TileSet"))
		assert(Exchange.snapshot(stage).is_empty())
		layer.tile_set = tiles
		assert(Exchange.snapshot(stage) == before)
		stage.free()
	assert(Exchange.snapshot_error(null).contains("直接開いて"))
	assert(Exchange.validate(null, {}, null).contains("JSON"))
	print("PASS: MapEdit saved-stage snapshot, JSON validation and exact missing-node/TileSet diagnostics")
	quit()

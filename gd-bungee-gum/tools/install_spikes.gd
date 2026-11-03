extends SceneTree
## Apply authored spike cells without regenerating unrelated stage content.
const Layout = preload("res://scripts/stage_layout.gd")
const STAGE_PATH := "res://scenes/stages/theater_stage.tscn"

func _initialize() -> void:
	var stage := load(STAGE_PATH).instantiate() as Node2D
	var spikes: TileMapLayer = stage.get_node("Spikes")
	spikes.clear()
	for cell in Layout.SPIKES:
		spikes.set_cell(cell, 0, Vector2i.ZERO, 0)
	var packed := PackedScene.new()
	assert(packed.pack(stage) == OK)
	assert(ResourceSaver.save(packed, STAGE_PATH) == OK)
	print("Saved ", spikes.get_used_cells().size(), " spike cells; other stage content preserved.")
	stage.free()
	quit()

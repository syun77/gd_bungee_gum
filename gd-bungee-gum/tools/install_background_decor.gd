extends SceneTree
## Updates only the decoration layer, preserving all other saved stage edits.
const Decor = preload("res://scripts/background_decor.gd")
const STAGE_PATH := "res://scenes/stages/theater_stage.tscn"

func _initialize() -> void:
	var stage := load(STAGE_PATH).instantiate() as Node2D
	var previous := stage.get_node_or_null("BackgroundDecor")
	if previous != null:
		stage.remove_child(previous)
		previous.free()
	var decor := Decor.create_layer()
	stage.add_child(decor)
	decor.owner = stage
	stage.move_child(decor, stage.get_node("TerrainTiles").get_index())
	var packed := PackedScene.new()
	assert(packed.pack(stage) == OK)
	assert(ResourceSaver.save(packed, STAGE_PATH) == OK)
	print("Saved ", decor.get_used_cells().size(), " background decorations; existing stage content preserved.")
	stage.free()
	quit()

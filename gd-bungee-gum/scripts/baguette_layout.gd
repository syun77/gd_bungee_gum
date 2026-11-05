extends RefCounted
## Saved stage positions in world pixels. Keep the editable stage scenes in sync.
const BAGUETTE = preload("res://scenes/items/baguette.tscn")
const THEATER_STAGE := [Vector2(208, 608), Vector2(1040, 672), Vector2(2640, 672)]
const STAGE_2 := [Vector2(240, 672), Vector2(464, 608), Vector2(1104, 672)]
const STAGE_3 := [Vector2(240, 672), Vector2(432, 672), Vector2(1104, 544)]

static func add_pickups(stage: Node2D, positions: Array) -> void:
	var pickups := Node2D.new()
	pickups.name = "Baguettes"
	stage.add_child(pickups)
	pickups.owner = stage
	for index in positions.size():
		var pickup := BAGUETTE.instantiate() as Area2D
		pickup.name = "Baguette%d" % (index + 1)
		pickup.position = positions[index]
		pickups.add_child(pickup)
		pickup.owner = stage

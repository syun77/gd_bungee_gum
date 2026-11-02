extends SceneTree

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var stage = load("res://scenes/stages/theater_stage.tscn").instantiate()
	root.add_child(stage)
	var player = load("res://scenes/characters/player.tscn").instantiate()
	root.add_child(player)
	var gum = load("res://scripts/gum_connection.gd").new()
	gum.settings = load("res://resources/game_settings.tres").duplicate()
	gum.player = player
	root.add_child(gum)
	await physics_frame
	await process_frame
	# Real merged floor ray at the entrance; exact top belongs to row20.
	player.position = Vector2(176, 620)
	gum.update_aim(Vector2(176, 680))
	check(gum.aim_valid, "Floor prediction attaches")
	check(gum.aim_tile_polygon.size() == 4, "Merged terrain resolves one cell")
	if gum.aim_tile_polygon.size() == 4:
		check(gum.aim_tile_polygon[0].is_equal_approx(Vector2(160, 640)), "Correct inward floor cell")
	gum.update_aim(Vector2(176, 680))
	check(gum.aim_blink_time > 0, "Same target advances blink")
	player.position = Vector2(208, 620)
	gum.update_aim(Vector2(208, 680))
	check(gum.aim_blink_time == 0, "New tile starts bright")
	gum.fire(Vector2.DOWN)
	gum.update_aim(Vector2(208, 680))
	check(gum.aim_tile_polygon.is_empty(), "Outbound hides tile")
	gum.state = gum.State.READY
	var anchors: TileMapLayer = stage.get_node("GumAnchors")
	var cell := anchors.get_used_cells()[0]
	var center := anchors.to_global(anchors.map_to_local(cell))
	player.position = center + Vector2(0, 114)
	gum.update_aim(center)
	check(gum.aim_valid and gum.aim_tile_polygon.size() == 4, "Ring ray highlights tile")
	if gum.aim_tile_polygon.size() == 4:
		check(gum.aim_tile_polygon[0].is_equal_approx(center - Vector2(16, 16)), "Ring uses RID cell")
	player.position = Vector2(10000, 10000)
	gum.update_aim(player.position + Vector2(100, -34))
	check(gum.aim_tile_polygon.is_empty(), "Miss clears highlight")
	print("Aim tile verification: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

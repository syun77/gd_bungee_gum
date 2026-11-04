extends SceneTree
const Layout = preload("res://scripts/stage_layout.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func verify() -> void:
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game._physics_process(game.entrance.TOTAL_TIME)
	game.set_physics_process(false)
	var layer: TileMapLayer = game.get_node("TheaterStage/Spikes")
	check(layer.get_used_cells().size() == 20, "Twenty authored spike cells")
	for cell in Layout.SPIKES:
		check(layer.get_cell_source_id(cell) == 0, "Saved spike matches layout %s" % cell)
		var supported := false
		for rect in Layout.TERRAIN:
			supported = supported or (cell.y + 1 == rect.position.y and cell.x >= rect.position.x and cell.x < rect.end.x)
		check(supported, "Spike base is on a real solid top %s" % cell)
		var center := Vector2(cell * 32) + Vector2(16, 16)
		for checkpoint in Layout.CHECKPOINTS:
			check(center.distance_to(checkpoint - Vector2(0, 26)) > 64, "Checkpoint has safe clearance")
		for key in ["PlayerSpawn", "LightBoxSpawn", "HeavyBoxSpawn", "Exit"]:
			check(center.distance_to(Layout.MARKERS[key]) > 64, "Spawn/workspace clearance: " + key)
	# Six local, real-physics approaches verify the floor strips need and permit a kick.
	# Each fixture starts on its own approach; this does not claim full-stage traversal.
	for index in range(0, 12, 2):
		var cell: Vector2i = Layout.SPIKES[index]
		var left: float = cell.x * 32.0
		var floor_y: float = (cell.y + 1) * 32.0
		game.player.position = Vector2(left - 64, floor_y)
		game.player.reset_motion()
		for i in 20:
			await physics_frame
			game.player.simulate(1.0 / 60.0, false)
		check(game._touches_spikes(game.player_shape.global_transform, Vector2(160, 0)), "Ground-level crossing is lethal")
		var kicked := false
		var hit := false
		Input.action_press("move_right")
		for i in 70:
			await physics_frame
			var before: Transform2D = game.player_shape.global_transform
			var kick: bool = not kicked and game.player.is_on_floor() and left - game.player.position.x < 50
			kicked = kicked or kick
			game.player.simulate(1.0 / 60.0, kick)
			hit = hit or game._touches_spikes(before, game.player_shape.global_position - before.origin)
			if game.player.position.x > left + 80:
				break
		Input.action_release("move_right")
		check(kicked and not hit and game.player.position.x > left + 80, "Floor strip %s clears with one physical kick" % cell)
	game.free()
	print("Spike placement verification: ", "PASS" if failures == 0 else "FAIL %d" % failures)
	quit(0 if failures == 0 else 1)

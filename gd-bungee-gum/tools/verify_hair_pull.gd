extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var player = load("res://scenes/characters/player.tscn").instantiate()
	root.add_child(player)
	var gum = load("res://scripts/gum_connection.gd").new()
	gum.settings = player.settings
	gum.player = player
	root.add_child(gum)
	player.gum = gum
	var anchor := StaticBody2D.new()
	root.add_child(anchor)
	gum.target = anchor
	gum.state = gum.State.ATTACHED
	gum.tension = 1500.0
	var shape = player.get_node("CollisionShape2D").shape
	for side in [-1, 1]:
		gum.path.points = PackedVector2Array([gum.origin(), gum.origin() + Vector2(100 * side, -50)])
		var forces := [Vector2(600 * side, -300), Vector2(900 * side, -450), Vector2(600 * side, -300), Vector2(500 * side, -250)]
		for index in forces.size():
			var force: Vector2 = forces[index]
			gum.player_force = force
			player._update_animation(0)
			check((player.sprite.animation == &"gum_hair_pull") == (index == 1 or index == 2), "Entry/hold/exit hysteresis")
			if absf(force.x) == 900:
				check(player.hair_pull_active and player.sprite.flip_h == (side < 0), "Strong force selects mirrored hair pose")
			if absf(force.x) == 500:
				check(not player.hair_pull_active, "Weak force exits")
		gum.player_force = Vector2(0, -2000)
		player._update_animation(0)
		check(not player.hair_pull_active, "Vertical force excluded")
		gum.player_force = Vector2(1000 * side, 500)
		player._update_animation(0)
		check(not player.hair_pull_active, "Downward art excluded")
	gum.player_force = Vector2(1000, -500)
	gum.state = gum.State.OUTBOUND
	player._update_animation(0)
	check(not player.hair_pull_active, "Outbound excluded")
	gum.state = gum.State.ATTACHED
	player.settings = player.settings.duplicate()
	player.settings.gum_hair_pull_force = 1500
	player._update_animation(0)
	check(not player.hair_pull_active, "Custom threshold respected")
	check(shape == player.get_node("CollisionShape2D").shape and player.scale == Vector2.ONE, "Physics geometry unchanged")
	player.settings.gum_hair_pull_force = 700
	player._update_animation(0)
	var first: int = player.sprite.frame
	await create_timer(0.25).timeout
	check(player.sprite.frame != first, "Hair temporal animation advances")
	check(player.sprite.sprite_frames.get_frame_count("gum_hair_pull") == 8, "Eight frames")
	player.free()
	gum.free()
	anchor.free()
	print("HAIR PULL: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

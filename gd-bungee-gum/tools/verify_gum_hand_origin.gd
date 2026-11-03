extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func verify() -> void:
	var player = load("res://scenes/characters/player.tscn").instantiate()
	root.add_child(player)
	player.settings = player.settings.duplicate()
	player.settings.hanging_pose_diagnostics = false
	player.settings.afterimage_enabled = false
	var gum = load("res://scripts/gum_connection.gd").new()
	gum.player = player
	gum.settings = player.settings
	root.add_child(gum)
	var physics_origin: Vector2 = gum.origin()
	var capsule: Shape2D = player.get_node("CollisionShape2D").shape
	player.external_velocity = Vector2(37, -45)
	for delta in [1.0 / 30.0, 1.0 / 60.0, 1.0 / 120.0]:
		for pose in [&"gum_fire", &"gum_hang", &"gum_pull", &"gum_hang_angles", &"jump"]:
			for mirrored in [false, true]:
				var before: Vector2 = player.gum_visual_origin()
				player.sprite.play(pose)
				player.sprite.pause()
				player.sprite.frame = 0
				player.sprite.flip_h = mirrored
				check(player.gum_visual_origin() == before, "Pose/flip never teleports ribbon origin")
				var target: Vector2 = player.gum_visual_target()
				var distance := before.distance_to(target)
				player._update_gum_hand_origin(delta)
				var moved: float = before.distance_to(player.gum_visual_origin())
				check(absf(moved - minf(distance, player.settings.gum_hand_follow_speed * delta)) < 0.001, "Hand displacement bounded per timestep")
				for tick in 60:
					player._update_gum_hand_origin(delta)
				check(player.gum_visual_origin().distance_to(target) < 0.001, "Origin settles exactly at sampled hand")
				check(gum.origin() == physics_origin and player.external_velocity == Vector2(37, -45), "Visual transition preserves physics origin/momentum")
	var before: Vector2 = player.gum_visual_origin()
	player.position += Vector2(120, -200)
	check(player.gum_visual_origin().is_equal_approx(before + Vector2(120, -200)), "Player translation follows instantly without world-space drag")
	player.sprite.scale *= Vector2(0.84, 1.41)
	before = player.gum_visual_origin()
	player._update_gum_hand_origin(1.0 / 60.0)
	check(before.distance_to(player.gum_visual_origin()) <= player.settings.gum_hand_follow_speed / 60.0 + 0.001, "Visual deformation also respects continuity")
	check(player.get_node("CollisionShape2D").shape == capsule and player.scale == Vector2.ONE, "Collision geometry remains unchanged")
	# Exercise the real simulation owner, including the food-lock early return.
	player.settings.gravity = 0.0
	for locked in [false, true]:
		player.food_reel_locked = locked
		player.sprite.play("gum_hang")
		player._update_gum_hand_origin(1.0)
		var local_before: Vector2 = player.gum_hand_offset
		await physics_frame
		player.simulate(1.0 / 60.0)
		check(local_before.distance_to(player.gum_hand_offset) > 0.0, "Simulation advances hand origin including food lock")
		check(local_before.distance_to(player.gum_hand_offset) <= player.settings.gum_hand_follow_speed / 60.0 + 0.001, "Simulation advances hand exactly once")
	player.free()
	gum.free()
	print("Gum hand origin: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

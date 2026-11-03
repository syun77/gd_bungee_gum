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
	var gum = load("res://scripts/gum_connection.gd").new()
	gum.settings = player.settings
	gum.player = player
	root.add_child(gum)
	player.gum = gum
	var anchor := StaticBody2D.new()
	root.add_child(anchor)
	gum.target = anchor
	gum.state = gum.State.ATTACHED
	gum.tension = 100.0
	player.velocity = Vector2.ZERO
	var collision_scale: Vector2 = player.get_node("CollisionShape2D").scale
	for side in [-1.0, 1.0]:
		for index in 6:
			var radians := deg_to_rad(10.0 * (index + 1))
			var direction := Vector2(sin(radians) * side, -cos(radians))
			# First bend, rather than the final target, owns the visible direction.
			gum.path.points = PackedVector2Array([gum.origin(), gum.origin() + direction * 400.0, gum.origin() + Vector2(0, -500)])
			player._update_animation(-side)
			check(player.sprite.animation == &"gum_hang_angles" and player.sprite.frame == index, "Direction selects frame %d side %s" % [index, side])
			check(not player.sprite.is_playing(), "Angular samples never autoplay")
			check(player.sprite.flip_h == (side < 0), "Gum direction owns mirroring")
			var hand: Vector2 = player.GUM_HANDS[&"gum_hang_angles"][index] - Vector2(128, 128)
			hand.x *= side
			check(player.gum_visual_target().is_equal_approx(player.sprite.to_global(hand)), "Ribbon target follows sampled mirrored hand")
			await process_frame
			check(player.sprite.frame == index, "Frame stays stable over render tick")
	# Exercise shared policy through animation selection, including initial zero-length flights.
	var samples := 0
	for state in [gum.State.ATTACHED, gum.State.OUTBOUND]:
		gum.state = state
		for side in [-1.0, 1.0]:
			for speed in [0.0, 150.0, 500.0]:
				player.velocity = Vector2(speed, 0)
				for radius in [2.0, 400.0]:
					for step in range(721):
						var angle := step * 0.25
						var radians := deg_to_rad(angle)
						var direction := Vector2(side * sin(radians), -cos(radians))
						gum.path.points = PackedVector2Array([gum.origin(), gum.origin() + direction * radius, gum.origin() + Vector2(0, -500)])
						gum.shot_direction = direction
						gum.tip = gum.origin()
						player._update_animation(0)
						var snapshot: Dictionary = player._hanging_pose_snapshot()
						check(absf(snapshot.angle_deg - angle) < 0.001, "Diagnostic records policy direction")
						if angle >= 70.0:
							var expected: StringName = &"gum_fire" if state == gum.State.OUTBOUND else &"gum_pull"
							check(snapshot.animation == expected, "Horizontal20deg sector/lower direction uses existing lateral pose")
						elif angle < 5.0:
							check(snapshot.animation == &"gum_hang", "Vertical pose independent of speed/distance/state")
						else:
							var expected := clampi(int(floor((angle + 4.999) / 10.0)) - 1, 0, 7)
							check(snapshot.animation == &"gum_hang_angles" and snapshot.frame == expected, "Quarter-degree policy angle=%s speed=%s radius=%s state=%s" % [angle, speed, radius, state])
							check(snapshot.nominal_angle_deg == (expected + 1) * 10.0, "Diagnostic reports selected nominal angle")
							check(absf(snapshot.selection_error_deg - (angle - snapshot.nominal_angle_deg)) < 0.001, "Diagnostic reports quantization error")
						samples += 1
	print("Verified %d quarter-degree cases, both sides/states, speeds0/150/500, distances2/400 and70deg boundary" % samples)
	gum.state = gum.State.ATTACHED
	player.velocity = Vector2.ZERO
	player.settings.hanging_pose_diagnostics = true
	player._update_animation(0)
	check(not player.hanging_diagnostic_key.is_empty(), "Enabled logging captures first selection")
	var next_tick: int = player.hanging_diagnostic_next_tick
	player._update_animation(0)
	check(player.hanging_diagnostic_next_tick == next_tick, "Unchanged selection is throttled")
	player.hanging_diagnostic_next_tick = 0
	player._update_animation(0)
	check(player.hanging_diagnostic_next_tick > 0, "Periodic sample schedules next summary")
	gum.target = null
	player._update_animation(0)
	check(player.hanging_diagnostic_key.is_empty(), "Detach emits exit and clears active state")
	gum.target = anchor
	player._update_animation(0)
	player.settings.hanging_pose_diagnostics = false
	player._update_animation(0)
	check(player.hanging_diagnostic_key.is_empty(), "Disabling logging clears capture")
	gum.path.points = PackedVector2Array([gum.origin(), gum.origin() + Vector2(0, -200)])
	player._update_animation(0)
	check(player.sprite.animation == &"gum_hang" and player.sprite.is_playing(), "Vertical connection retains hanging loop")
	player.velocity = Vector2(150, 0)
	player._update_animation(0)
	check(player.sprite.animation == &"gum_hang", "Fast vertical traction keeps raised arm")
	player.velocity = Vector2.ZERO
	gum.tension = 0
	player._update_animation(0)
	check(player.sprite.animation == &"jump", "Slack airborne connection retains ordinary air pose")
	gum.state = gum.State.OUTBOUND
	gum.shot_direction = Vector2.UP
	gum.tip = gum.origin()
	player.fire_gum()
	check(player.sprite.animation == &"gum_hang", "Upward firing raises hand immediately at zero-length tip")
	gum.shot_direction = Vector2.RIGHT
	player.fire_gum()
	check(player.sprite.animation == &"gum_fire", "Horizontal firing uses lateral fire pose")
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(0, 20)
	var floor_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(200, 40)
	floor_shape.shape = rectangle
	floor_body.add_child(floor_shape)
	root.add_child(floor_body)
	gum.target = null
	gum.state = gum.State.READY
	gum.tension = 0
	player.position = Vector2.ZERO
	player.reset_motion()
	for tick in 3:
		await physics_frame
		player.simulate(1.0 / 60.0)
	check(player.is_on_floor(), "Grounded fire fixture has real support")
	gum.fire(Vector2.UP)
	var momentum: Vector2 = player.external_velocity
	player.fire_gum()
	check(player.sprite.animation == &"gum_hang" and player.is_on_floor(), "Grounded upward firing raises arm without removing support")
	check(player.external_velocity == momentum, "Firing pose does not change physical momentum")
	floor_body.free()
	check(player.get_node("CollisionShape2D").scale == collision_scale and player.rotation == 0.0, "Pose selection never deforms physics")
	player.free()
	gum.free()
	anchor.free()
	print("Hanging poses: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

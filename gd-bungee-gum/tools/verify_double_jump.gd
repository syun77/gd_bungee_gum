extends SceneTree

const STEP := 1.0 / 60.0

func _initialize() -> void:
	call_deferred("verify")

func tick(player, jump := false, attached := false) -> void:
	await physics_frame
	player.simulate(STEP, jump, attached)
	await process_frame

func verify() -> void:
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(4000, 40)
	shape.shape = rectangle
	floor_body.position.y = 660
	floor_body.add_child(shape)
	root.add_child(floor_body)
	var player = load("res://scenes/characters/player.tscn").instantiate()
	player.settings = load("res://resources/game_settings.tres").duplicate()
	player.settings.kick_speed = 310.0
	player.settings.double_jump_kick_speed = 470.0
	player.settings.double_jump_rotation_speed = 2.5
	player.position.y = 630
	root.add_child(player)
	for i in 20:
		await tick(player)
	assert(player.is_on_floor())
	var capsule = player.get_node("CollisionShape2D")
	var capsule_transform: Transform2D = capsule.transform
	var floor_before: Vector2 = player.external_velocity
	await tick(player, true)
	assert(is_equal_approx(player.external_velocity.y, floor_before.y + player.settings.gravity * STEP - player.settings.kick_speed), "Initial jump uses its independent Kick Speed")
	assert(player.air_jump_available and not player.double_jump_spinning, "Floor jump keeps air allowance and remains upright")
	await tick(player)
	player.external_velocity = Vector2(75, 180)
	await tick(player, true)
	assert(not player.air_jump_available and player.double_jump_spinning)
	assert(player.sprite.animation == &"double_jump" and player.sprite.frame == 0, "Spin uses the knees-hugged pose")
	var tuck_texture = player.sprite.sprite_frames.get_frame_texture(&"double_jump", 0)
	assert(tuck_texture is AtlasTexture and tuck_texture.region == Rect2(328, 145, 606, 935))
	assert(player.sprite.scale.is_equal_approx(player.sprite_rest_scale * player.settings.jump_stretch * player.DOUBLE_JUMP_ART_SCALE), "Tuck preserves head scale and shared jump deformation")
	assert(player.external_velocity.is_equal_approx(Vector2(75, -player.settings.double_jump_kick_speed)), "Air jump uses Double Jump Kick Speed, cancels descent and retains horizontal momentum")
	assert(not is_zero_approx(player.sprite.rotation) and player.rotation == 0.0)
	assert(capsule.transform == capsule_transform, "Rotation never reaches collider")
	var gum = load("res://scripts/gum_connection.gd").new()
	gum.player = player
	gum.settings = player.settings
	root.add_child(gum)
	player.gum = gum
	gum.state = gum.State.OUTBOUND
	player.settings.hanging_pose_diagnostics = false
	for direction in [-1.0, 1.0]:
		player._update_animation(direction)
		assert(player.sprite.animation == &"double_jump", "Outbound gum cannot replace spinning tuck")
		assert(player.sprite.flip_h == (direction < 0.0), "Tuck mirrors with movement input")
		var hand: Vector2 = player.DOUBLE_JUMP_HAND_OFFSET
		hand.x *= direction
		assert(player.gum_visual_target().is_equal_approx(player.sprite.to_global(hand)), "Visual hand follows rotated tucked artwork")
	player.gum = null
	gum.queue_free()
	var before: Vector2 = player.external_velocity
	await tick(player, true)
	assert(player.external_velocity.is_equal_approx(before + Vector2(0, player.settings.gravity * STEP)), "Third jump rejected")
	var rotation_before: float = player.sprite.rotation
	await tick(player)
	assert(not is_equal_approx(rotation_before, player.sprite.rotation), "Rotation continues without further input")
	assert(is_equal_approx(load("res://scripts/game_settings.gd").new().double_jump_rotation_speed, 2.5), "Schema matches saved baseline")
	for speed in [1.0, 4.0, 0.0]:
		player.settings.double_jump_rotation_speed = speed
		for direction in [-1.0, 0.0, 1.0, 0.0]:
			if direction != 0.0:
				Input.action_press("move_left" if direction < 0.0 else "move_right")
			rotation_before = player.sprite.rotation
			before = player.external_velocity
			var facing_left: bool = direction < 0.0 if direction != 0.0 else player.sprite.flip_h
			await tick(player)
			Input.action_release("move_left")
			Input.action_release("move_right")
			var sign := -1.0 if facing_left else 1.0
			var expected := fposmod(rotation_before + TAU * STEP * speed * sign, TAU)
			assert(is_equal_approx(player.sprite.rotation, expected), "Live speed and current facing control spin; neutral keeps facing, zero freezes")
			assert(player.sprite.flip_h == facing_left and player.sprite.animation == &"double_jump", "Tuck follows facing through midair reversals")
			assert(player.external_velocity.is_equal_approx(before + Vector2(0, player.settings.gravity * STEP)), "Facing and spin never change external momentum")
			assert(capsule.transform == capsule_transform and player.rotation == 0.0, "Both spin directions leave collision geometry unchanged")
	player.settings.double_jump_rotation_speed = 2.5
	for i in 100:
		await tick(player)
		if player.is_on_floor():
			break
	assert(player.is_on_floor() and player.sprite.rotation == 0.0 and not player.double_jump_spinning)
	assert(player.sprite.animation != &"double_jump" and player.sprite.scale.x > player.sprite_rest_scale.x, "Landing restores ordinary art and landing squash")
	await tick(player, true)
	await tick(player)
	assert(player.air_jump_available, "Landing restores the next airborne jump")
	player.external_velocity = Vector2(-90, -120)
	await tick(player, true)
	assert(player.external_velocity.is_equal_approx(Vector2(-90, -player.settings.double_jump_kick_speed)), "Double jump replaces existing upward momentum")
	# Special gum jump remains usable without refreshing an exhausted air jump.
	before = player.external_velocity
	await tick(player, true, true)
	assert(is_equal_approx(player.external_velocity.y, before.y + player.settings.gravity * STEP - player.settings.kick_speed), "Gum release keeps initial Kick Speed even after double jump")
	assert(not player.air_jump_available)
	player.reset_motion()
	assert(not player.double_jump_spinning and player.sprite.rotation == 0.0 and not player.air_jump_available, "Motion reset clears artwork but cannot refill air jumps")
	# A player spawned airborne can use the allowance without a prior floor jump.
	player.position.y = 200
	player.air_jump_available = true
	await tick(player)
	await tick(player, true)
	assert(player.double_jump_spinning and not player.air_jump_available)
	player.food_reel_locked = true
	await tick(player, true)
	assert(player.sprite.rotation == 0.0 and not player.double_jump_spinning and player.velocity == Vector2.ZERO)
	assert(player.sprite.animation != &"double_jump", "Reel reset restores ordinary pose")
	player.food_reel_locked = false
	await verify_vertical_speed_assignment(player)
	player.queue_free()
	floor_body.queue_free()
	await process_frame
	await process_frame
	print("Double jump verification PASS: shared launch physics, one air allowance, floor refill, rotation lifecycle, fixed collision, gum priority and reel lock")
	quit()

func verify_vertical_speed_assignment(player) -> void:
	for gravity in [0.0, 1100.0, 5000.0]:
		player.settings.gravity = gravity
		for delta in [1.0 / 30.0, 1.0 / 60.0, 1.0 / 120.0]:
			for vertical_speed in [-500.0, -1.0, 0.0, 800.0]:
				for horizontal_speed in [-100.0, 100.0]:
					player.position = Vector2(10000, -1000)
					player.reset_motion()
					await tick(player)
					player.air_jump_available = true
					player.external_velocity = Vector2(horizontal_speed, vertical_speed)
					await physics_frame
					player.simulate(delta, true)
					await process_frame
					var expected := Vector2(horizontal_speed, -player.settings.double_jump_kick_speed)
					assert(player.external_velocity.is_equal_approx(expected), "Double jump assigns the same upward speed regardless of gravity or prior vertical momentum; X stays intact")
					assert(not player.air_jump_available)
					await physics_frame
					player.simulate(delta)
					await process_frame
					assert(player.external_velocity.is_equal_approx(expected + Vector2(0, gravity * delta)), "Gravity resumes immediately after launch")
	print("PASS:72 double-jump launch cases across gravity, timesteps and upward/downward/horizontal momentum")

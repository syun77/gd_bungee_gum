extends SceneTree

const STEP := 1.0 / 60.0

func _initialize() -> void:
	call_deferred("verify")

func step(player, pressed := false) -> void:
	await physics_frame
	player.simulate(STEP, pressed)
	await process_frame

func verify() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1000, 40)
	shape.shape = rectangle
	floor_body.position = Vector2(0, 660)
	floor_body.add_child(shape)
	world.add_child(floor_body)
	for duration in [0.12, 0.0]:
		var player = load("res://scenes/characters/player.tscn").instantiate()
		player.settings = load("res://resources/game_settings.tres").duplicate()
		player.settings.jump_buffer_time = duration
		player.position = Vector2(0, 630)
		world.add_child(player)
		await step(player)
		player.external_velocity = Vector2(0, 240)
		player.air_jump_available = false
		await step(player, true)
		assert(player.external_velocity.y > 0, "Buffered input must not create an air jump")
		var launched := false
		for index in 10:
			await step(player)
			if player.external_velocity.y < -100:
				launched = true
		assert(launched == (duration > 0), "Pre-landing input must launch only when enabled")
		for index in 65:
			await step(player)
		assert(player.is_on_floor(), "Consumed buffer must not repeat")
		player.queue_free()
		await process_frame
	var player = load("res://scenes/characters/player.tscn").instantiate()
	player.settings = load("res://resources/game_settings.tres").duplicate()
	player.settings.jump_buffer_time = 0.12
	player.position = Vector2(0, 450)
	world.add_child(player)
	player.air_jump_available = false
	await step(player, true)
	for index in 70:
		await step(player)
		assert(player.external_velocity.y >= 0, "Expired input must never launch on landing")
	assert(player.is_on_floor() and player.jump_buffer_remaining == 0, "Expired input must not launch")
	player.position.y = 450
	await step(player)
	await step(player, true)
	player.food_reel_locked = true
	await step(player)
	assert(player.jump_buffer_remaining == 0, "Reeling must clear pending input")
	player.food_reel_locked = false
	await step(player, true)
	player.reset_motion()
	assert(player.jump_buffer_remaining == 0, "Motion reset must clear pending input")
	print("Jump buffer verification PASS")
	quit()

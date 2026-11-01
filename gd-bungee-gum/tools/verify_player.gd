extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func ticks(count: int) -> void:
	for index in count:
		await physics_frame
		await process_frame

func verify() -> void:
	var game: Node2D = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	var player = game.get_node("Player")
	var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
	await ticks(40)
	assert(player.is_on_floor(), "Player must land on stage")
	assert(sprite.animation == &"idle")
	assert(absf(player.position.y - 640.0) < 1.0, "Feet must align with floor")
	var start_x: float = player.position.x
	Input.action_press("move_right")
	await ticks(12)
	assert(player.position.x > start_x + 10.0)
	assert(sprite.animation == &"run")
	Input.action_release("move_right")
	Input.action_press("kick_off")
	await ticks(2)
	assert(not player.is_on_floor())
	assert(player.velocity.y < 0.0)
	assert(sprite.animation == &"jump")
	Input.action_release("kick_off")
	await ticks(3)
	var rising_speed: float = player.velocity.y
	Input.action_press("kick_off")
	await ticks(2)
	assert(player.velocity.y > rising_speed, "Air input must not add a second impulse")
	Input.action_release("kick_off")
	await ticks(55)
	assert(player.is_on_floor())
	assert(sprite.animation == &"idle")
	player.external_velocity = Vector2(-200.0, 0.0)
	player.position = Vector2(80, 640)
	await ticks(25)
	assert(player.position.x >= 73.0)
	assert(absf(player.external_velocity.x) < 0.1, "Wall must clear inward external momentum")
	print("PASS: spawn, floor alignment, idle/run/jump/landing, no air jump, wall momentum cleanup")
	quit()

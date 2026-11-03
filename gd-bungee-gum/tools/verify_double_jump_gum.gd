extends SceneTree

var game: Node2D

func _initialize() -> void:
	call_deferred("verify")

func ticks(count := 1) -> void:
	for i in count:
		await physics_frame
		await process_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func verify() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	var player = game.player
	var gum = game.gum
	var settings = game.settings.duplicate()
	settings.attachment_range = 400.0
	settings.maximum_length = 900.0
	settings.gum_shot_speed = 1200.0
	settings.hanging_pose_diagnostics = false
	game.settings = settings
	player.settings = settings
	gum.settings = settings
	# Isolated airborne lab on the actual Game fixed-step/input pipeline.
	var anchor := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(300, 24)
	shape.shape = rectangle
	anchor.add_child(shape)
	anchor.position = Vector2(10000, 200)
	game.add_child(anchor)
	player.position = Vector2(10000, 460)
	player.reset_motion()
	await ticks(2)
	key(KEY_Z, true)
	await ticks()
	key(KEY_Z, false)
	await ticks()
	assert(player.double_jump_spinning and not player.air_jump_available)
	key(KEY_UP, true)
	key(KEY_X, true)
	await ticks()
	key(KEY_X, false)
	assert(gum.state == gum.State.OUTBOUND)
	assert(player.double_jump_spinning and not player.air_jump_available, "Firing alone cannot restore jump or stop spin")
	for i in 25:
		await ticks()
		if gum.connected():
			break
	key(KEY_UP, false)
	assert(gum.connected(), "Swept flight must attach to actual terrain")
	assert(not player.double_jump_spinning and player.sprite.rotation == 0.0)
	assert(player.sprite.animation != &"double_jump" and player.air_jump_available, "Arrival immediately restores ordinary art and one double jump")
	for i in 3:
		await ticks()
		assert(not player.double_jump_spinning)
	key(KEY_Z, true)
	await ticks()
	key(KEY_Z, false)
	await ticks()
	assert(not gum.connected() and player.air_jump_available and not player.double_jump_spinning, "Release jump preserves restored air allowance")
	key(KEY_Z, true)
	await ticks()
	key(KEY_Z, false)
	await ticks()
	assert(player.double_jump_spinning and not player.air_jump_available, "Fresh airborne press uses restored double jump")
	# Direct adhesion checks the same event, preserving all physical momentum.
	var before: Vector2 = player.external_velocity
	assert(gum.attach_at(anchor.position))
	assert(player.external_velocity == before, "Adhesion spin reset never changes momentum")
	assert(player.air_jump_available and not player.double_jump_spinning and player.sprite.rotation == 0.0)
	player.air_jump_available = false
	await ticks(2)
	assert(not player.air_jump_available, "Holding attachment cannot continuously refill air jumps")
	gum.detach()
	var food = load("res://scenes/items/foods/milano_doria.tscn").instantiate()
	food.position = gum.origin() + Vector2(100, 0)
	game.add_child(food)
	await ticks()
	assert(gum.attach_at(food.global_position) and gum.reeling_food())
	assert(not player.air_jump_available, "Food reel does not restore the normal air allowance")
	for code in [KEY_Z, KEY_X, KEY_UP]:
		key(code, false)
	game.queue_free()
	await process_frame
	print("Gum double jump PASS: real flight/arrival, immediate spin cancellation, one-shot refill, release and fresh double jump, momentum preservation")
	quit()

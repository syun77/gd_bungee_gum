extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func tick(player, jump := false) -> void:
	await physics_frame
	player.simulate(1.0 / 60.0, jump)
	await process_frame

func verify() -> void:
	var player = load("res://scenes/characters/player.tscn").instantiate()
	root.add_child(player)
	player.settings = player.settings.duplicate()
	player.settings.jump_diagnostics = false
	player.settings.landing_diagnostics = false
	player.settings.jump_stretch = Vector2(0.8, 1.25)
	player.settings.jump_stretch_duration = 0.24
	player.settings.landing_squash = Vector2(1.3, 0.7)
	player.settings.landing_squash_duration = 0.22
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1000, 32)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(0, 116)
	root.add_child(floor_body)
	player.position = Vector2(0, 90)
	for i in 30:
		await tick(player)
	var capsule = player.get_node("CollisionShape2D")
	var original_shape = capsule.shape
	var original_transform: Transform2D = capsule.transform
	var rest_scale: Vector2 = player.sprite.scale
	var rest_position: Vector2 = player.sprite.position
	check(rest_scale.is_equal_approx(Vector2.ONE * 0.3125), "Spawn does not squash")
	await tick(player, true)
	check(player.sprite.scale.is_equal_approx(rest_scale * player.settings.jump_stretch), "Jump uses custom settings multipliers")
	check(player.sprite.scale.x < rest_scale.x and player.sprite.scale.y > rest_scale.y, "Accepted upward kick stretches vertically")
	check(player.sprite.position.is_equal_approx(rest_position * (player.sprite.scale / rest_scale)), "Visual deformation keeps feet pivot")
	await tick(player, true)
	check(player.visual_deformation_time < player.settings.jump_stretch_duration - 0.02, "Rejected airborne kick does not restart stretch")
	var landed := false
	for i in 90:
		await tick(player)
		check(capsule.shape == original_shape and capsule.transform == original_transform and player.scale == Vector2.ONE, "Collision geometry and body scale stay fixed")
		if player.is_on_floor():
			landed = true
			break
	check(player.sprite.scale.is_equal_approx(rest_scale * player.settings.landing_squash), "Landing uses custom settings multipliers")
	check(landed and player.sprite.scale.x > rest_scale.x and player.sprite.scale.y < rest_scale.y, "Actual landing squashes vertically")
	for i in 30:
		await tick(player)
	check(player.sprite.scale.is_equal_approx(rest_scale) and player.sprite.position.is_equal_approx(rest_position), "Standing recovers exact rest transform without retrigger")
	player.settings.jump_stretch_duration = 0.0
	await tick(player, true)
	check(player.sprite.scale.is_equal_approx(rest_scale), "Zero duration disables deformation without division by zero")
	print("Player deformation: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

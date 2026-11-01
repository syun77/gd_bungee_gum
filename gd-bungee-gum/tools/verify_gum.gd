extends SceneTree
## Physics lab: actual ray queries and rigid-body force integration, no canned movement.
var failures := 0
var world: Node2D
var player: CharacterBody2D
var gum: Node2D

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		failures += 1

func ticks(count: int) -> void:
	for index in count:
		await physics_frame
		await process_frame

func body_at(point: Vector2, rigid := false) -> PhysicsBody2D:
	var body: PhysicsBody2D = RigidBody2D.new() if rigid else StaticBody2D.new()
	body.position = point
	body.collision_layer = 4 if rigid else 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(40, 40)
	shape.shape = rectangle
	body.add_child(shape)
	world.add_child(body)
	if rigid:
		(body as RigidBody2D).gravity_scale = 0.0
		(body as RigidBody2D).linear_damp = 0.0
	return body

func verify_mouse_bindings() -> void:
	for binding in [[MOUSE_BUTTON_LEFT, "gum_attach"], [MOUSE_BUTTON_RIGHT, "gum_contract"], [MOUSE_BUTTON_MIDDLE, "gum_detach"]]:
		var press := InputEventMouseButton.new()
		press.button_index = binding[0]
		press.pressed = true
		Input.parse_input_event(press)
		Input.flush_buffered_events()
		check(Input.is_action_pressed(binding[1]), "Mouse binding: " + binding[1])
		var release := InputEventMouseButton.new()
		release.button_index = binding[0]
		Input.parse_input_event(release)
		Input.flush_buffered_events()
		check(not Input.is_action_pressed(binding[1]), "Mouse release: " + binding[1])

func verify() -> void:
	verify_mouse_bindings()
	world = Node2D.new()
	root.add_child(world)
	player = load("res://scenes/characters/player.tscn").instantiate()
	world.add_child(player)
	gum = load("res://scripts/gum_connection.gd").new()
	gum.settings = load("res://resources/gum_settings.tres")
	gum.player = player
	world.add_child(gum)
	var wall := body_at(Vector2(220, -34))
	await ticks(2)
	check(gum.attach_at(wall.position), "Ray must attach to static terrain")
	check(absf(gum.rest_length - 200.0) < 0.1, "Attach uses current distance")
	gum.step(1.0 / 60.0, false)
	check(gum.tension == 0.0, "Fresh attachment must not exert force")
	gum.rest_length = 300.0
	player.velocity = Vector2(-500, 0)
	gum.step(1.0 / 60.0, false)
	check(gum.tension == 0.0, "Slack spring has no damping force")
	gum.rest_length = 200.0
	player.velocity = Vector2.ZERO
	gum.step(1.0 / 60.0, true)
	check(gum.rest_length < 200.0 and gum.tension > 0.0, "Contraction must generate pull")
	var saved_length: float = gum.rest_length
	gum.step(1.0 / 60.0, false)
	check(gum.rest_length == saved_length, "Releasing contraction holds length")
	player.velocity = Vector2(-10000, 0)
	gum.step(1.0 / 60.0, false)
	check(gum.tension == gum.settings.maximum_tension, "Tension is capped")
	player.velocity = Vector2.ZERO
	var saved_velocity: Vector2 = player.external_velocity
	gum.detach()
	check(player.external_velocity == saved_velocity, "Detach must retain momentum exactly")
	gum.attach_at(wall.position)
	var blocker := body_at(Vector2(100, -34))
	await ticks(2)
	gum.step(1.0 / 60.0, false)
	check(not gum.connected() and gum.release_reason == "OBSTRUCTED", "Terrain obstruction must release")
	blocker.add_to_group("gum_blocked")
	check(not gum.attach_at(wall.position), "Blocked first hit must not attach behind it")
	blocker.free()
	await ticks(2)
	gum.attach_at(wall.position)
	player.position.x = -1000.0
	gum.step(1.0 / 60.0, false)
	check(not gum.connected() and gum.release_reason == "TOO FAR", "Maximum length releases without teleport")
	player.position = Vector2.ZERO
	wall.free()
	var box := body_at(Vector2(220, -34), true) as RigidBody2D
	await ticks(2)
	check(gum.attach_at(box.position), "Ray must attach to dynamic box")
	var local_point: Vector2 = gum.target_local_point
	box.rotation = 0.2
	check(gum.endpoint().is_equal_approx(box.to_global(local_point)), "Adhesion tracks local point through rotation")
	box.angular_velocity = 2.0
	var radius: Vector2 = gum.endpoint() - box.to_global(box.center_of_mass)
	check(gum.target_point_velocity().is_equal_approx(box.linear_velocity + Vector2(-radius.y, radius.x) * 2.0), "Point velocity includes angular motion")
	box.rotation = 0.0
	box.angular_velocity = 0.0
	box.mass = 0.4
	await ticks(2)
	gum.attach_at(box.position)
	gum.rest_length = 150.0
	player.external_velocity = Vector2.ZERO
	player.velocity = Vector2.ZERO
	gum.step(1.0 / 60.0, false)
	check((gum.player_force + gum.target_force).length() < 0.001, "Endpoint forces must be equal and opposite")
	await ticks(2)
	check(box.linear_velocity.x < 0.0 and player.external_velocity.x > 0.0, "Actual rigid integration pulls box and player together")
	check(absf(box.linear_velocity.x) > player.external_velocity.x, "Light box accelerates more than player")
	gum.detach()
	box.linear_velocity = Vector2.ZERO
	box.mass = 6.0
	player.external_velocity = Vector2.ZERO
	await ticks(2)
	gum.attach_at(box.position)
	gum.rest_length = 150.0
	gum.step(1.0 / 60.0, false)
	await ticks(2)
	check(player.external_velocity.x > absf(box.linear_velocity.x), "Heavy box accelerates less than player")
	# An off-center hit must create actual torque, not only linear movement.
	gum.detach()
	box.free()
	box = body_at(Vector2(220, -50), true) as RigidBody2D
	await ticks(2)
	gum.attach_at(Vector2(220, -60))
	gum.rest_length = 150.0
	gum.step(1.0 / 60.0, false)
	await ticks(2)
	check(absf(box.angular_velocity) > 0.001, "Off-center gum force rotates rigid body")
	box.free()
	gum.step(1.0 / 60.0, false)
	check(not gum.connected() and gum.tension == 0.0, "Deleted endpoint releases safely")
	# Swing from a fixed ceiling point using the same force->controller sequence as Game.
	var ceiling := body_at(Vector2(0, -260))
	player.position = Vector2.ZERO
	player.external_velocity = Vector2(160, 0)
	player.velocity = player.external_velocity
	await ticks(2)
	check(gum.attach_at(ceiling.position), "Ceiling attachment for swing")
	for index in 180:
		gum.step(1.0 / 60.0, index < 40)
		player.simulate(1.0 / 60.0)
		await ticks(1)
	check(gum.connected() and player.position.is_finite(), "Swing/contraction remains connected and finite")
	check(player.velocity.length() < 1200.0, "Swing remains in stable velocity range")
	saved_velocity = player.external_velocity
	gum.detach()
	check(player.external_velocity == saved_velocity, "Swing release keeps tangential momentum")
	world.free()
	var game: Node2D = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await ticks(40)
	var game_gum: Node2D = game.get_node("Gum")
	var game_player: CharacterBody2D = game.get_node("Player")
	check(game_gum.attach_at(Vector2(160, 100)), "Game can attach to restaurant ceiling")
	game_player.fire_gum()
	Input.action_press("gum_contract")
	await ticks(10)
	check(game_player.get_node("AnimatedSprite2D").animation == &"gum_fire", "Fire pose integrated with controller")
	await ticks(90)
	check(game_player.position.y < 600.0, "Game coordinator contracts and lifts player")
	check(game_player.get_node("AnimatedSprite2D").animation in [&"gum_pull", &"gum_hang"], "Taut airborne connection uses gum pose")
	Input.action_release("gum_contract")
	Input.action_press("gum_detach")
	await ticks(2)
	check(not game_gum.connected(), "Detach input handled by coordinator")
	check(game_player.get_node("AnimatedSprite2D").animation == &"jump", "Detach returns to airborne animation")
	Input.action_release("gum_detach")
	game.free()
	if failures == 0:
		print("PASS: mouse bindings, gum ray/blocked hit, slack, contraction/hold, release momentum, occlusion, maximum length, rotating endpoint, reciprocal forces and light/heavy rigid response, target deletion; live Game lift/poses/detach")
	quit(1 if failures else 0)

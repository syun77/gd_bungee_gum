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

func step_lab(contract := false) -> void:
	# Select a mode explicitly to isolate the force-law cases below.
	if gum.connected():
		gum.mode = gum.Mode.CONTRACT if contract else gum.Mode.LOOSEN
	gum.step(1.0 / 60.0)

func verify() -> void:
	world = Node2D.new()
	root.add_child(world)
	player = load("res://scenes/characters/player.tscn").instantiate()
	world.add_child(player)
	gum = load("res://scripts/gum_connection.gd").new()
	gum.settings = load("res://resources/game_settings.tres").duplicate()
	gum.player = player
	world.add_child(gum)
	var wall := body_at(Vector2(220, -34))
	await ticks(2)
	check(gum.attach_at(wall.position), "Ray must attach to static terrain")
	check(absf(gum.rest_length - 200.0) < 0.1, "Attach uses current distance")
	step_lab()
	check(gum.tension == 0.0, "Fresh attachment must not exert force")
	check(gum.mode == gum.Mode.LOOSEN, "Lab force isolation selected fixed-length mode")
	gum.mode = gum.Mode.CONTRACT
	gum.relax()
	var loose_length: float = gum.rest_length
	player.position.x = -80.0
	gum.step(1.0 / 60.0)
	check(gum.mode == gum.Mode.LOOSEN and gum.rest_length == loose_length and gum.tension > 0.0, "Fixed-length loosen regains spring support when stretched")
	gum.contract()
	check(gum.mode == gum.Mode.CONTRACT, "Explicit contract resumes even with nonzero tension")
	player.position.x = 0.0
	gum.relax()
	for delta in [1.0 / 30.0, 1.0 / 60.0, 1.0 / 120.0]:
		gum.rest_length = 100.0
		gum.step(delta, 1.0)
		check(is_equal_approx(gum.rest_length, 100.0 + gum.settings.manual_extension_speed * delta), "Manual extension follows delta")
		check(gum.mode == gum.Mode.LOOSEN and gum.tension > 0.0, "Relaxed extension preserves spring tension")
		gum.rest_length = 100.0
		gum.step(delta, -1.0)
		check(is_equal_approx(gum.rest_length, 100.0 - gum.settings.manual_shortening_speed * delta) and gum.mode == gum.Mode.LOOSEN, "Manual shortening keeps relaxed mode")
	gum.rest_length = gum.manual_length_limit() - 1.0
	gum.step(0.1, 1.0)
	check(gum.rest_length == gum.manual_length_limit() and gum.rest_length < gum.settings.maximum_length, "Manual extension reserves break margin")
	gum.rest_length = gum.settings.maximum_length - 1.0
	gum.step(0.1, 1.0)
	check(gum.rest_length == gum.settings.maximum_length - 1.0, "Above-cap attachment never snaps shorter on extension")
	gum.rest_length = 40.0
	gum.step(1.0, -1.0)
	check(gum.rest_length == gum.settings.minimum_length, "Manual shortening respects lower bound")
	gum.rest_length = 10.0
	gum.step(0.1, -1.0)
	check(gum.rest_length <= 10.0, "Short attachment never extends on shortening")
	gum.rest_length = 300.0
	player.velocity = Vector2(-500, 0)
	step_lab()
	check(gum.tension == 0.0, "Slack spring has no damping force")
	gum.rest_length = 200.0
	player.velocity = Vector2.ZERO
	step_lab(true)
	check(gum.rest_length < 200.0 and gum.tension > 0.0, "Contraction must generate pull")
	var saved_length: float = gum.rest_length
	step_lab()
	check(gum.rest_length == saved_length, "Releasing contraction holds length")
	player.velocity = Vector2(-10000, 0)
	step_lab()
	check(gum.tension == gum.settings.maximum_tension, "Tension is capped")
	player.velocity = Vector2.ZERO
	var saved_velocity: Vector2 = player.external_velocity
	gum.detach()
	check(player.external_velocity == saved_velocity, "Detach must retain momentum exactly")
	gum.attach_at(wall.position)
	var blocker := body_at(Vector2(100, -34))
	await ticks(2)
	step_lab()
	check(gum.connected() and gum.path.pivots.size() == 2, "Terrain obstruction must wrap around two corners")
	var total_force: Vector2 = gum.player_force + gum.target_force
	for force in gum.terrain_forces:
		total_force += force
	check(total_force.length() < 0.001, "Wrapped forces balance including terrain reaction")
	gum.mode = gum.Mode.CONTRACT
	var before_relax: float = gum.rest_length
	gum.relax()
	check(gum.rest_length == before_relax, "Wrapped relax preserves natural length and tension")
	gum.step(0.1, 1.0)
	var expected_length: float = maxf(before_relax, minf(gum.manual_length_limit(), before_relax + gum.settings.manual_extension_speed * 0.1))
	check(is_equal_approx(gum.rest_length, expected_length), "Wrapped extension adjusts total natural length within manual cap")
	var wrapped_velocity: Vector2 = player.external_velocity
	gum.detach()
	check(player.external_velocity == wrapped_velocity and gum.path.pivots.is_empty(), "Wrapped detach clears pivots and preserves momentum")
	# Total route can exceed the limit while the endpoint chord remains below it.
	gum.target = wall
	gum.target_local_point = Vector2(-20,0)
	gum.mode = gum.Mode.LOOSEN
	gum.path.reset(gum.origin(),gum.endpoint())
	var saved_maximum: float = gum.settings.maximum_length
	gum.settings.maximum_length = 202.0
	step_lab()
	check(not gum.connected() and gum.release_reason == "TOO FAR", "Total path limit applies despite shorter straight distance")
	gum.settings.maximum_length = saved_maximum
	blocker.add_to_group("gum_blocked")
	check(not gum.attach_at(wall.position), "Blocked first hit must not attach behind it")
	blocker.free()
	await ticks(2)
	gum.attach_at(wall.position)
	player.position.x = -1000.0
	step_lab()
	check(not gum.connected() and gum.release_reason == "TOO FAR", "Maximum length releases without teleport")
	player.position = Vector2.ZERO
	wall.free()
	# A dynamic object crossing the route is explicitly unsupported, never a ghost force.
	wall = body_at(Vector2(220,-34))
	await ticks(2)
	gum.attach_at(wall.position)
	var crossing := body_at(Vector2(100,-34),true)
	await ticks(2)
	step_lab()
	check(not gum.connected() and gum.release_reason == "UNSUPPORTED OBSTACLE", "Dynamic obstruction has explicit safe release")
	crossing.free()
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
	step_lab()
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
	step_lab()
	await ticks(2)
	check(player.external_velocity.x > absf(box.linear_velocity.x), "Heavy box accelerates less than player")
	# An off-center hit must create actual torque, not only linear movement.
	gum.detach()
	box.free()
	box = body_at(Vector2(220, -50), true) as RigidBody2D
	await ticks(2)
	gum.attach_at(Vector2(220, -60))
	gum.rest_length = 150.0
	step_lab()
	await ticks(2)
	check(absf(box.angular_velocity) > 0.001, "Off-center gum force rotates rigid body")
	box.free()
	step_lab()
	check(not gum.connected() and gum.tension == 0.0, "Deleted endpoint releases safely")
	# Swing from a fixed ceiling point using the same force->controller sequence as Game.
	var ceiling := body_at(Vector2(0, -260))
	player.position = Vector2.ZERO
	player.external_velocity = Vector2(160, 0)
	player.velocity = player.external_velocity
	await ticks(2)
	check(gum.attach_at(ceiling.position), "Ceiling attachment for swing")
	for index in 180:
		step_lab(index < 40)
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
	# Saved-map ceiling/wrapping fixture intentionally uses a 900px range.
	game.settings = game.settings.duplicate()
	game.settings.maximum_length = 900.0
	game.gum.settings = game.settings
	game.player.settings = game.settings
	await ticks(40)
	var game_gum: Node2D = game.get_node("Gum")
	var game_player: CharacterBody2D = game.get_node("Player")
	check(game_gum.attach_at(Vector2(160, 100)), "Game can attach to restaurant ceiling")
	game_player.fire_gum()
	await ticks(10)
	check(game_player.get_node("AnimatedSprite2D").animation == &"gum_fire", "Fire pose integrated with controller")
	await ticks(90)
	check(game_player.position.y < 600.0, "Game coordinator contracts and lifts player")
	check(game_player.get_node("AnimatedSprite2D").animation in [&"gum_pull", &"gum_hang"], "Taut airborne connection uses gum pose")
	Input.action_press("jump")
	await ticks(2)
	check(not game_gum.connected(), "Detach input handled by coordinator")
	check(game_player.get_node("AnimatedSprite2D").animation == &"jump", "Detach returns to airborne animation")
	Input.action_release("jump")
	game.set_physics_process(false)
	game_player.position = Vector2(750,450)
	game_player.external_velocity = Vector2.ZERO
	game_player.velocity = Vector2.ZERO
	check(game_gum.attach_at(Vector2(750,100)), "Live map attachment beside overhead shelf")
	game_player.position.x = 1000.0
	game_gum.step(1.0/60.0)
	check(game_gum.connected() and not game_gum.path.pivots.is_empty(), "Live map shelf wraps instead of cutting")
	check(game_gum.player_force.x < 0.0 and game_gum.player_force.y < 0.0, "Live map force follows first shelf corner")
	for tick in 120:
		game_gum.step(1.0/60.0)
		game_player.simulate(1.0/60.0)
		await ticks(1)
	check(game_gum.connected() and game_player.position.is_finite(), "Live map corner contraction remains stable")
	game_gum.detach()
	game_player.position = Vector2(2700,514)
	game_player.external_velocity = Vector2(200,-50)
	game_player.velocity = game_player.external_velocity
	check(game_gum.attach_at(Vector2(2742,100)), "Section 04 ceiling anchor before shelf contact")
	game_gum.mode = game_gum.Mode.LOOSEN
	game_gum.rest_length = 250.0
	game_player.position.x = 2760.0
	game_gum.step(1.0/60.0)
	check(game_gum.connected() and game_gum.support_point().is_equal_approx(Vector2(2751,385)), "Section 04 chooses contacted shelf bottom-left, not lower floor")
	check(game_gum.player_force.y < 0 and game_player.external_velocity.y < -50, "Section 04 contact tension pulls upward without false downward kick")
	game.free()
	if failures == 0:
		print("PASS: gum ray/blocked hit, slack, contraction/hold, release momentum, corner wrapping/terrain reactions/path limit, dynamic obstruction, maximum length, rotating endpoint, reciprocal forces and light/heavy rigid response, target deletion; live Game lift/poses/detach")
	quit(1 if failures else 0)

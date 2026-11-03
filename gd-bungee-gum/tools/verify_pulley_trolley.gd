extends SceneTree
## Actual adhesion drives one powered segment; engine integrates motor and gum forces.
var failures := 0
var world: Node2D
var trolley: Node2D
var carriage: RigidBody2D
var player: CharacterBody2D
var gum: Node2D

func _initialize() -> void:
	call_deferred("verify")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func ticks(count: int, simulate := false, step_gum := false) -> void:
	for i in count:
		await physics_frame
		if step_gum:
			gum.step(1.0 / 60.0)
		if simulate:
			player.simulate(1.0 / 60.0, false)
		await process_frame

func setup_lab(mode := 1, route := PackedVector2Array()) -> void:
	if is_instance_valid(world):
		world.free()
	world = Node2D.new()
	root.add_child(world)
	trolley = load("res://scenes/props/pulley_trolley.tscn").instantiate()
	trolley.route_mode = mode
	if not route.is_empty():
		trolley.route_points = route
	world.add_child(trolley)
	carriage = trolley.get_node("Carriage")
	player = load("res://scenes/characters/player.tscn").instantiate()
	world.add_child(player)
	gum = load("res://scripts/gum_connection.gd").new()
	gum.settings = load("res://resources/game_settings.tres").duplicate()
	gum.player = player
	world.add_child(gum)
	trolley.bind(gum)
	player.position = carriage.position + Vector2(0, 120)

func hit() -> void:
	gum.detach("RESTART")
	player.position = carriage.position + Vector2(0, 120)
	player.external_velocity = Vector2.ZERO
	player.velocity = Vector2.ZERO
	check(gum.attach_at(carriage.global_position + Vector2(0, 42)), "Real ray adhesion hits moving pad")
	check(gum.target == carriage, "Connection belongs to physical carriage")

func wait_for_arrival(expected: int) -> void:
	for i in 240:
		await ticks(1)
		if not trolley.moving:
			break
	check(not trolley.moving and trolley.current_point == expected, "Motor arrives at waypoint %s" % expected)
	check(carriage.position.distance_to(trolley.points[expected]) <= 3.1, "Physical carriage settles near authored waypoint")

func verify() -> void:
	setup_lab()
	await ticks(30)
	check(not trolley.moving and trolley.current_point == 0 and carriage.position.distance_to(Vector2(80, 0)) < 0.1, "No hit means no automatic travel")
	hit()
	check(trolley.moving and trolley.destination_point == 1, "Adhesion starts exactly next segment")
	await ticks(10)
	check(carriage.position.x > 80.0, "Motor moves carriage through real physics")
	hit()
	check(trolley.destination_point == 1, "A second hit during movement does not skip destination")
	gum.detach("RESTART")
	await wait_for_arrival(1)
	await ticks(30)
	check(not trolley.moving and trolley.current_point == 1, "Arrival waits for a new hit; no queued moving hit")
	# Repeated physical adhesions trace both route modes through full cycles.
	for mode in [0, 1]:
		setup_lab(mode, PackedVector2Array([Vector2(80, 0), Vector2(128, 0), Vector2(176, 0)]))
		await ticks(2)
		var expected := [1, 2, 0, 1] if mode == 0 else [1, 2, 1, 0, 1]
		for point in expected:
			hit()
			gum.detach("RESTART")
			await wait_for_arrival(point)
	# Native guide and rendered rail can follow a closed two-dimensional route.
	setup_lab(0, PackedVector2Array([Vector2(80, 0), Vector2(128, -48), Vector2(176, 0)]))
	await ticks(2)
	for point in [1, 2, 0]:
		hit()
		gum.detach("RESTART")
		await wait_for_arrival(point)
	check(trolley.get_node("Rails").get_child_count() == 3, "Loop renders closing rail segment")
	# Continuous adhesion never triggers the next waypoint; hanging still uses a spring.
	setup_lab()
	await ticks(2)
	hit()
	var lowest_feet := player.position.y
	var peak := 0.0
	for i in 150:
		await ticks(1, true, true)
		lowest_feet = maxf(lowest_feet, player.position.y)
		peak = maxf(peak, gum.tension)
		check(not player.is_on_floor(), "Gum hanging grants no floor support")
		check(gum.player_force.is_equal_approx(-gum.target_force), "Motor preserves reciprocal gum forces")
	check(gum.connected() and lowest_feet < 180.0 and peak > 0.0, "Spring supports player while motor carries attachment")
	check(trolley.current_point == 1 and not trolley.moving, "Sustained attachment waits after one segment")
	gum.detach("RESTART")
	var released_y := player.position.y
	await ticks(45, true)
	check(player.position.y > released_y + 100.0, "Release preserves physical player fall")
	# Wheel and pad cannot act as a platform even while a motor is present.
	setup_lab()
	player.position = Vector2(80, -30)
	await ticks(60, true)
	check(not player.is_on_floor() and player.position.y > 200.0, "Player passes through pulley")
	check(carriage.collision_layer == 16 and carriage.collision_mask == 0 and not carriage.has_node("Platform"), "Only gum sees pad collision")
	var box: RigidBody2D = load("res://scenes/props/gum_box.tscn").instantiate()
	box.position = Vector2(80, -50)
	world.add_child(box)
	await ticks(60)
	check(box.position.y > 200.0, "Props pass through pulley")
	world.free()
	# Real saved Game flight triggers movement only on arrival, with normal bindings.
	var game: Node2D = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await ticks(3)
	game.set_physics_process(false)
	player = game.player
	gum = game.gum
	trolley = game.get_node("PulleyTrolley")
	carriage = trolley.get_node("Carriage")
	check(trolley.position == Vector2(944, 384), "Saved elevated placement")
	player.position = Vector2(1024, 512)
	player.reset_motion()
	await ticks(2, true)
	check(player.is_on_floor(), "Upper platform supports elevated approach")
	gum.update_aim(carriage.global_position + Vector2(0, 42))
	check(not trolley.moving, "Preview does not activate motor")
	gum.fire(Vector2.UP)
	check(not trolley.moving, "Shot launch alone does not activate motor")
	await ticks(8, true, true)
	check(gum.connected() and gum.target == carriage and trolley.moving and trolley.destination_point == 1, "Game arrival triggers next waypoint")
	current_scene = game
	game.restart()
	await ticks(3)
	trolley = current_scene.get_node("PulleyTrolley")
	carriage = trolley.get_node("Carriage")
	check(not trolley.moving and trolley.current_point == 0 and trolley.direction == 1 and carriage.position.distance_to(Vector2(80, 0)) < 0.1, "R resets route index/direction/motor and physical carriage")
	current_scene.free()
	print("PULLEY TROLLEY: ", "PASS" if failures == 0 else "FAIL", " (", failures, ")")
	quit(0 if failures == 0 else 1)

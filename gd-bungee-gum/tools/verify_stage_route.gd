extends SceneTree
## Walks the saved map from entrance to exit with real gum flights and saved tuning.
const Layout = preload("res://scripts/stage_layout.gd")
var player: CharacterBody2D
var gum: Node2D
var failures := 0
var peak_tension := 0.0

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func tick(kick := false) -> void:
	await physics_frame
	gum.step(1.0 / 60.0)
	player.simulate(1.0 / 60.0, kick)
	peak_tension = maxf(peak_tension, gum.tension)
	await process_frame

func walk_to(x: float) -> bool:
	Input.action_press("move_right")
	var stalled := 0
	for i in 1500:
		var before := player.position.x
		await tick(player.is_on_floor() and (player.is_on_wall() or stalled >= 10))
		stalled = stalled + 1 if player.position.x - before < 0.1 else 0
		if player.position.x >= x - 8:
			break
	Input.action_release("move_right")
	for i in 30:
		await tick()
	check(absf(player.position.x - x) < 40, "Walk to %s reached %s" % [x, player.position])
	return absf(player.position.x - x) < 40

func settle_at_or_above(y: float) -> bool:
	for i in 180:
		await tick()
		if player.is_on_floor() and player.position.y <= y + 1:
			return true
	check(false, "Expected landing at/above %s, got %s" % [y, player.position])
	return false

func verify() -> void:
	var game: Node2D = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game._physics_process(game.entrance.TOTAL_TIME)
	game.set_physics_process(false)
	player = game.player
	gum = game.gum
	player.settings = game.settings.duplicate()
	player.settings.landing_diagnostics = false
	player.settings.jump_diagnostics = false
	player.settings.pinning_diagnostics = false
	player.settings.gum_diagnostics = false
	gum.settings = player.settings
	for i in 40:
		await tick()
	# Measure actual fixed-step kick with this map and saved settings.
	var floor_y := player.position.y
	var min_y := floor_y
	await tick(true)
	for i in 90:
		await tick()
		min_y = minf(min_y, player.position.y)
		if player.is_on_floor():
			break
	var rise := floor_y - min_y
	check(rise >= 64 and rise < 128, "Current kick must fit the 64px stair / 128px gum design")
	print("Measured saved-tuning kick rise: ", rise)
	for index in Layout.LIFTS.size():
		var lift: Dictionary = Layout.LIFTS[index]
		if not await walk_to(lift.start.x):
			break
		check(absf(player.position.y - lift.start.y) < 1, "Lift %s starts on its authored floor: %s" % [index, player.position])
		# A bare kick must not reach the 128px landing shelf.
		await tick(true)
		var kick_min := player.position.y
		for i in 90:
			await tick()
			kick_min = minf(kick_min, player.position.y)
			if player.is_on_floor():
				break
		check(kick_min > lift.landing_y + 20, "Lift %s must require gum" % index)
		gum.fire(Vector2.UP)
		var attached := false
		var rose := false
		for i in 240:
			await tick()
			attached = attached or gum.connected()
			if player.position.y < lift.landing_y - 8:
				rose = true
				break
		check(attached and rose, "Lift %s must attach within saved range and rise: %s" % [index, player.position])
		gum.detach()
		if not await settle_at_or_above(lift.landing_y):
			break
		print("Lift ", index + 1, " landed ", player.position)
		# Four 64px shelves connect the gum landing to the solid exit or upper beam.
		if lift.has("kick_y") and player.position.y > lift.kick_y + 1:
			await tick(true)
			if not await settle_at_or_above(lift.kick_y):
				break
	if failures == 0:
		await walk_to(Layout.MARKERS.Exit.x)
		check(player.is_on_floor() and absf(player.position.y - Layout.MARKERS.Exit.y) < 1, "Full lower route reaches exit")
	check(peak_tension > player.settings.gravity * player.settings.player_mass, "Real gum tension must lift player against gravity")
	game.free()
	if failures == 0:
		print("PASS: entrance-to-exit route, seven real gum lifts, 64px kicks, saved tuning and no teleports")
	quit(1 if failures else 0)

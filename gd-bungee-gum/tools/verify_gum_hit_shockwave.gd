extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("verify")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func verify() -> void:
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var effect = game.get_node("GumHitShockwave")
	effect.settings = game.settings.duplicate()
	effect.settings.gum_hit_shockwave_duration = 0.32
	effect.set_process(false)
	var box = game.get_node("LightBox")
	box.freeze = true
	box.position = Vector2(10000, 200)
	game.player.position = Vector2(9900, 234)
	await physics_frame
	await process_frame
	check(effect.bursts.is_empty(), "No wave before hit")
	game.gum.fire(Vector2.RIGHT)
	check(effect.bursts.is_empty(), "Firing does not emit wave")
	for i in 30:
		game.gum.step(1.0 / 60.0, 0.0)
		if game.gum.connected():
			break
	check(game.gum.connected() and effect.bursts.size() == 1, "Real arrival emits wave")
	check(game.gum.player_force.is_zero_approx(), "Arrival remains force free")
	if not effect.bursts.is_empty():
		var quad = effect.bursts[0].quad
		check(is_equal_approx(quad.material.get_shader_parameter("quad_radius"), effect.settings.gum_hit_shockwave_radius), "Shader radial coordinates match quad geometry")
		var center: Vector2 = quad.global_position
		check(center.is_equal_approx(game.gum.endpoint()), "Wave centered at adhesion")
		box.position += Vector2(30, 20)
		game.gum.detach()
		effect._process(0.16)
		check(quad.global_position.is_equal_approx(center), "Release and motion preserve center")
		check(is_equal_approx(quad.material.get_shader_parameter("progress"), 0.5), "Shader progress advances")
		effect._process(0.17)
		check(effect.bursts.is_empty(), "Wave expires")
	for i in 8:
		effect._start(Vector2.UP, true)
	check(effect.bursts.size() == 4, "Burst cap")
	effect.settings.gum_hit_shockwave_enabled = false
	effect._process(0.01)
	check(effect.bursts.is_empty(), "Disable clears waves")
	effect.settings.gum_hit_shockwave_enabled = true
	effect.settings.gum_hit_shockwave_duration = 0.0
	effect._start(Vector2.UP, false)
	check(effect.bursts.is_empty(), "Zero duration disables")
	effect.settings.gum_hit_shockwave_duration = 0.32
	effect._start(Vector2.UP, false)
	effect.stop()
	check(effect.bursts.is_empty(), "Restart cleanup")
	game.free()
	print("Gum shockwave verification: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

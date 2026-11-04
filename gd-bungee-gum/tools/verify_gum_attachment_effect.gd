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
	game._physics_process(game.entrance.TOTAL_TIME)
	game.set_physics_process(false)
	game.settings = game.settings.duplicate()
	game.gum.settings = game.settings
	game.settings.gum_diagnostics = false
	var gum = game.gum
	var effect = game.get_node("GumAttachmentEffect")
	effect.set_process(false)
	var box = game.get_node("LightBox")
	box.freeze = true
	box.position = Vector2(10000, 200)
	game.player.position = Vector2(9900, 234)
	await physics_frame
	await process_frame
	check(not effect.visible, "READY has no effect")
	gum.fire(Vector2.RIGHT)
	check(not effect.visible, "Firing has no adhesion effect")
	for i in 30:
		gum.step(1.0 / 60.0, 0.0)
		if gum.connected():
			break
	check(gum.connected() and effect.visible, "Actual shot arrival starts effect")
	check(effect.texture == effect.SURFACE and effect.frame == 0, "Surface texture starts at frame zero")
	check(gum.player_force.is_zero_approx(), "Arrival remains force-free")
	var start: Vector2 = effect.global_position
	box.position += Vector2(20, -10)
	box.rotation = 0.4
	effect._process(0.10)
	check(effect.global_position.is_equal_approx(gum.endpoint()) and not effect.global_position.is_equal_approx(start), "Effect follows rotating/translating adhesion")
	check(is_equal_approx(effect.global_rotation, 0.4), "Surface orientation follows body rotation")
	check(effect.frame == 3, "Frame timing is 30fps")
	gum.contract()
	check(effect.frame == 3, "Contraction does not retrigger")
	effect._process(0.20)
	check(not effect.visible, "Effect ends at 0.30s")
	gum.detach()
	box.rotation = 0.0
	await physics_frame
	await process_frame
	check(gum.attach_at(box.position), "Direct fixture adhesion succeeds")
	check(effect.visible, "New adhesion restarts effect")
	gum.detach()
	check(not effect.visible, "Detach hides immediately")
	for normal in [Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		gum._attach_hit({"collider": box, "rid": box.get_rid(), "position": box.position, "normal": normal})
		check(Vector2.LEFT.rotated(effect.global_rotation).is_equal_approx(normal), "Wall/ceiling/floor orientation follows hit normal")
		gum.detach()
	check(gum.attach_at(box.position), "Restart fixture adhesion succeeds")
	gum.detach("RESTART")
	check(not effect.visible, "Restart hides an active effect immediately")
	check(not gum.attach_at(Vector2(9900, 0)) and not effect.visible, "Miss does not show effect")
	var anchors := TileMapLayer.new()
	anchors.tile_set = game.get_node("TheaterStage/GumAnchors").tile_set
	anchors.physics_quadrant_size = 1
	anchors.position = Vector2(10000, -200)
	anchors.set_cell(Vector2i.ZERO, 2, Vector2i.ZERO)
	game.add_child(anchors)
	var center := anchors.to_global(anchors.map_to_local(Vector2i.ZERO))
	game.player.position = center + Vector2(-100, 34)
	await physics_frame
	await process_frame
	check(gum.attach_at(center + Vector2(0, 10)), "Off-center ring adhesion succeeds")
	check(effect.visible and effect.texture == effect.RING, "Ring uses radial texture")
	check(effect.global_position.is_equal_approx(center) and is_zero_approx(effect.global_rotation), "Ring effect stays at resolved center")
	anchors.erase_cell(Vector2i.ZERO)
	await physics_frame
	await process_frame
	effect._process(0.01)
	check(not effect.visible, "Erased target hides effect")
	gum.detach("RESTART")
	check(not effect.visible, "Restart clears effect")
	game.queue_free()
	await process_frame
	print("Gum attachment effect: ", "PASS" if failures == 0 else "FAIL", " (", failures, ")")
	quit(0 if failures == 0 else 1)

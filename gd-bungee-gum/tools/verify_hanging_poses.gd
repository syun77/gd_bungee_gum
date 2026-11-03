extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func verify() -> void:
	var player = load("res://scenes/characters/player.tscn").instantiate()
	root.add_child(player)
	var gum = load("res://scripts/gum_connection.gd").new()
	gum.settings = player.settings
	gum.player = player
	root.add_child(gum)
	player.gum = gum
	var anchor := StaticBody2D.new()
	root.add_child(anchor)
	gum.target = anchor
	gum.state = gum.State.ATTACHED
	gum.tension = 100.0
	player.velocity = Vector2.ZERO
	var collision_scale: Vector2 = player.get_node("CollisionShape2D").scale
	for side in [-1.0, 1.0]:
		for index in 8:
			var radians := deg_to_rad(10.0 * (index + 1))
			var direction := Vector2(sin(radians) * side, -cos(radians))
			# First bend, rather than the final target, owns the visible direction.
			gum.path.points = PackedVector2Array([gum.origin(), gum.origin() + direction * 400.0, gum.origin() + Vector2(0, -500)])
			player._update_animation(-side)
			check(player.sprite.animation == &"gum_hang_angles" and player.sprite.frame == index, "Direction selects frame %d side %s" % [index, side])
			check(not player.sprite.is_playing(), "Angular samples never autoplay")
			check(player.sprite.flip_h == (side < 0), "Gum direction owns mirroring")
			var hand: Vector2 = player.GUM_HANDS[&"gum_hang_angles"][index] - Vector2(128, 128)
			hand.x *= side
			check(player.gum_visual_origin().is_equal_approx(player.sprite.to_global(hand)), "Ribbon follows sampled mirrored hand")
			await process_frame
			check(player.sprite.frame == index, "Frame stays stable over render tick")
	gum.path.points = PackedVector2Array([gum.origin(), gum.origin() + Vector2(0, -200)])
	player._update_animation(0)
	check(player.sprite.animation == &"gum_hang" and player.sprite.is_playing(), "Vertical connection retains hanging loop")
	player.velocity = Vector2(150, 0)
	player._update_animation(0)
	check(player.sprite.animation == &"gum_pull", "Fast traction retains pull pose")
	player.velocity = Vector2.ZERO
	gum.tension = 0
	player._update_animation(0)
	check(player.sprite.animation == &"jump", "Slack airborne connection retains ordinary air pose")
	gum.state = gum.State.OUTBOUND
	player._update_animation(0)
	check(player.sprite.animation == &"gum_fire", "Outbound fire retains priority")
	check(player.get_node("CollisionShape2D").scale == collision_scale and player.rotation == 0.0, "Pose selection never deforms physics")
	player.free()
	gum.free()
	anchor.free()
	print("Hanging poses: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

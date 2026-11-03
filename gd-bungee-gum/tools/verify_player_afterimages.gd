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
	player.settings = player.settings.duplicate()
	player.settings.afterimage_enabled = true
	player.settings.afterimage_minimum_speed = 350.0
	player.settings.afterimage_lifetime = 0.20
	player.settings.afterimage_interval = 0.04
	player.settings.gravity = 0.0
	player.settings.jump_diagnostics = false
	player.settings.landing_diagnostics = false
	await physics_frame
	player.external_velocity = Vector2(220, 0)
	player.simulate(1.0 / 60)
	check(player.afterimages.images.is_empty(), "Normal run speed produces no afterimages")
	player.external_velocity = Vector2(0, -500)
	await physics_frame
	player.simulate(1.0 / 60)
	check(player.afterimages.images.size() == 1, "Actual fast vertical movement emits")
	var ghost: Sprite2D = player.afterimages.images[0].sprite
	check(not ghost.z_as_relative and ghost.z_index < player.afterimages._world_z_index(player.sprite), "Top-level snapshot renders behind player artwork")
	check(ghost.material == player.afterimages.silhouette_material and ghost.material.shader != null, "Snapshots use shared silhouette shader")
	check(ghost.modulate == player.settings.afterimage_color, "Silhouette uses configured color and opacity")
	check(player.sprite.material == null, "Player artwork retains original colors")
	var frozen := ghost.global_transform
	var texture := ghost.texture
	var opacity := ghost.modulate.a
	player.sprite.flip_h = not player.sprite.flip_h
	player.global_position += Vector2(80, 30)
	player.afterimages.step(0.02, player.sprite, 0, player.settings)
	check(ghost.global_transform == frozen and ghost.texture == texture, "Snapshot pose and world transform remain frozen")
	check(ghost.modulate.a < opacity, "Snapshot fades")
	player.afterimages.step(0.3, player.sprite, 0, player.settings)
	check(player.afterimages.images.is_empty(), "Slowing down allows residue to expire")
	for i in 30:
		player.afterimages.step(0.001, player.sprite, 500, player.settings)
		player.afterimages.cooldown = 0.0
	check(player.afterimages.images.size() <= 8, "Snapshot count bounded")
	player.settings.afterimage_enabled = false
	player.afterimages.step(0.01, player.sprite, 500, player.settings)
	check(player.afterimages.images.is_empty(), "Disable clears effect")
	player.settings.afterimage_enabled = true
	player.settings.afterimage_minimum_speed = 600.0
	player.afterimages.step(0.01, player.sprite, 500, player.settings)
	check(player.afterimages.images.is_empty(), "Custom speed threshold respected")
	player.settings.afterimage_lifetime = 0.0
	player.afterimages.step(0.01, player.sprite, 1000, player.settings)
	check(player.afterimages.images.is_empty(), "Zero lifetime safely disables effect")
	player.free()
	print("Player afterimages: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

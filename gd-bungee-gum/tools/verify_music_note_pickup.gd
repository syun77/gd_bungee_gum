extends SceneTree

var pickups := 0

func _initialize() -> void:
	call_deferred("verify")

func ticks() -> void:
	for i in 5:
		await physics_frame
		await process_frame

func verify() -> void:
	var player = load("res://scenes/characters/player.tscn").instantiate()
	player.position = Vector2(-1000, -1000)
	root.add_child(player)
	var box := RigidBody2D.new()
	box.collision_layer = 4
	box.gravity_scale = 0.0
	var collision := CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	box.add_child(collision)
	root.add_child(box)
	for stage_name in ["theater_stage", "stage_2", "stage_3"]:
		var packed = load("res://scenes/stages/%s.tscn" % stage_name)
		var stage = packed.instantiate()
		root.add_child(stage)
		await ticks()
		var layer: TileMapLayer = stage.get_node("MusicNotes")
		var count := layer.get_child_count()
		var note = layer.get_child(0)
		var target: Vector2 = note.global_position
		note.collected.connect(func(): pickups += 1)
		var before := pickups
		box.position = target
		await ticks()
		assert(is_instance_valid(note), "Rigid props cannot collect notes")
		# A player-layer body also needs the player group.
		box.collision_layer = 2
		box.position = target + Vector2(0, 2)
		await ticks()
		assert(is_instance_valid(note), "Unrelated player-layer bodies cannot collect")
		box.collision_layer = 4
		box.position = Vector2(-800, -1000)
		var ray := PhysicsRayQueryParameters2D.create(target - Vector2(20, 0), target + Vector2(20, 0), 53)
		ray.collide_with_areas = true
		var hit := layer.get_world_2d().direct_space_state.intersect_ray(ray)
		assert(hit.is_empty() or hit.collider != note, "Gum rays ignore notes")
		paused = true
		player.position = target + Vector2(0, 26)
		await ticks()
		assert(is_instance_valid(note) and pickups == before, "Paused contact does not collect")
		paused = false
		await ticks()
		assert(not is_instance_valid(note), "Player physically overlaps and collects saved scene tile")
		assert(pickups == before + 1 and layer.get_child_count() == count - 1, "Pickup removes exactly one note")
		player.position = Vector2(-1000, -1000)
		stage.free()
		await ticks()
		stage = packed.instantiate()
		root.add_child(stage)
		await ticks()
		assert(stage.get_node("MusicNotes").get_child_count() == count, "Stage reload restores notes")
		stage.free()
		await ticks()
	# Duplicate requests in the same frame emit once and hide immediately.
	var standalone = load("res://scenes/items/music_note.tscn").instantiate()
	root.add_child(standalone)
	standalone.collected.connect(func(): pickups += 1)
	var before := pickups
	standalone.collect()
	standalone.collect()
	assert(pickups == before + 1 and not standalone.visible, "Duplicate pickup is harmless")
	await process_frame
	player.free()
	box.free()
	print("PASS: music note player contact across3stages, props/group filtering, gum exclusion, pause, reload and one-shot pickup")
	quit()

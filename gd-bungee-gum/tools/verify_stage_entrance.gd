extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame

func verify() -> void:
	for path in ["res://scenes/game.tscn", "res://scenes/game_stage_2.tscn", "res://scenes/game_stage_3.tscn"]:
		var game = load(path).instantiate()
		root.add_child(game)
		var entrance = game.entrance
		var player = game.player
		var start: Vector2 = player.global_position
		check(entrance.active and entrance.frame == 0 and not player.sprite.visible, "Starts closed with hidden character: " + path)
		check(entrance.z_index == player.z_index and entrance.get_index() < player.get_index(), "Door draws behind character")
		for action in ["move_right", "jump", "gum_action"]:
			Input.action_press(action)
		await ticks(20)
		check(entrance.active and entrance.frame > 0 and not player.sprite.visible, "Doors open before emergence")
		check(player.global_position == start and player.external_velocity == Vector2.ZERO, "No movement/gravity during opening")
		check(not game.gum.connected() and not game.gum.visible, "Gum input/preview blocked")
		while not player.sprite.visible:
			await ticks(1)
		check(player.sprite.visible and player.sprite.self_modulate.r < 0.2, "Character emerges nearly black")
		check(player.sprite.animation == &"entrance_front" and not player.sprite.is_playing(), "Emergence uses static front pose")
		check(not player.sprite.flip_h, "Front pose is unmirrored")
		var pose: Texture2D = player.sprite.sprite_frames.get_frame_texture(&"entrance_front", 0)
		check(pose.resource_path == "res://assets/characters/teto_front_entrance.png" and pose.get_size() == Vector2(256, 256), "Normalized front artwork selected")
		var open_frame: int = entrance.frame
		await ticks(12)
		check(entrance.frame < open_frame and player.sprite.self_modulate.r > 0.4, "Closing and color recovery happen together")
		check(player.global_position == start, "Movement remains locked during fade")
		check(player.sprite.animation == &"entrance_front", "Front pose remains throughout fade/closing")
		Input.action_release("move_right")
		await ticks(20)
		check(not entrance.active and entrance.frame == 0, "Sequence finishes closed")
		check(player.sprite.self_modulate == Color.WHITE and player.sprite.visible, "Character normal color restored")
		check(player.sprite.animation != &"entrance_front", "Gameplay animations resume after entrance")
		check(not game.gum.connected(), "Held suppressed shot never queues")
		check(player.external_velocity.y >= 0.0, "Held suppressed jump never queues")
		Input.action_release("jump")
		Input.action_release("gum_action")
		await ticks(3)
		check(player.is_on_floor(), "Entrance baseline matches floor")
		Input.action_press("move_right")
		await ticks(6)
		Input.action_release("move_right")
		check(player.global_position.x > start.x + 5.0, "Movement resumes after sequence")
		game.free()
		await process_frame
	# A valid checkpoint restoration must remain immediately playable.
	var path := "res://scenes/game_stage_2.tscn"
	var game = load(path).instantiate()
	game.scene_file_path = path
	set_meta(&"checkpoint_respawn", {"scene": path, "checkpoint": NodePath("TheaterStage/Checkpoints/Checkpoint01")})
	root.add_child(game)
	check(not game.entrance.active and game.player.sprite.visible, "Checkpoint skips entrance sequence")
	check(not game.active_checkpoint.is_empty(), "Checkpoint restored")
	check(game.player.sprite.animation != &"entrance_front", "Checkpoint uses normal gameplay artwork")
	game.free()
	await process_frame
	print("Stage entrance: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

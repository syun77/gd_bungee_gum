extends SceneTree
const STEP := 1.0 / 60.0
func _initialize() -> void:
	call_deferred("verify")
func step(player, jump := false) -> void:
	await physics_frame
	player.simulate(STEP, jump)
	await process_frame
func verify() -> void:
	var stage = load("res://scenes/stages/theater_stage.tscn").instantiate()
	root.add_child(stage)
	var player = load("res://scenes/characters/player.tscn").instantiate()
	player.settings = load("res://resources/game_settings.tres").duplicate()
	player.position = Vector2(464, 640)
	root.add_child(player)
	await step(player)
	Input.action_press("aim_up")
	var climb_frames := {}
	for i in 20:
		await step(player)
		climb_frames[player.sprite.frame] = true
	assert(player.sprite.animation == &"climb" and player.sprite.is_playing() and not player.sprite.flip_h, "Rear-facing climb animation plays")
	assert(player.sprite.sprite_frames.get_frame_count(&"climb") == 2 and climb_frames.size() == 2, "Both alternating climb poses play")
	assert(is_instance_valid(player.ladder) and player.position.y < 610, "Up climbs saved ladder")
	Input.action_release("aim_up")
	var held_y: float = player.position.y
	await step(player)
	var held_frame: int = player.sprite.frame
	for i in 20:
		await step(player)
	assert(not player.sprite.is_playing() and player.sprite.frame == held_frame, "Neutral freezes current climb pose")
	assert(absf(player.position.y - held_y) < 0.1, "Neutral holds without gravity drift")
	Input.action_press("aim_up")
	for i in 60:
		await step(player)
	assert(player.is_on_floor() and absf(player.position.y - 512) < 1.0, "Top exits onto actual one-way shelf")
	Input.action_release("aim_up")
	await step(player)
	Input.action_press("aim_down")
	for i in 15:
		await step(player)
	assert(is_instance_valid(player.ladder) and player.position.y > 530, "Down enters through one-way top")
	await step(player, true)
	assert(not is_instance_valid(player.ladder) and player.external_velocity.y < -300, "Z releases with contact kick")
	assert(player.get_collision_mask_value(4), "Release restores one-way collision")
	await step(player)
	assert(not is_instance_valid(player.ladder), "Held input cannot immediately regrab")
	Input.action_release("aim_down")
	player.position = Vector2(464, 600)
	player.reset_motion()
	await step(player)
	Input.action_press("aim_up")
	await step(player)
	Input.action_press("move_right")
	await step(player)
	assert(not is_instance_valid(player.ladder), "Horizontal input exits")
	Input.action_release("move_right")
	Input.action_release("aim_up")
	await step(player)
	# Descend to the bottom and regain ordinary floor support.
	player.position = Vector2(464, 600)
	player.reset_motion()
	await step(player)
	Input.action_press("aim_down")
	for i in 30:
		await step(player)
	assert(not is_instance_valid(player.ladder) and player.is_on_floor(), "Bottom exits to floor")
	assert(player.get_collision_mask_value(4))
	Input.action_release("aim_down")
	await step(player)
	player.settings.ladder_speed = 0
	player.position = Vector2(464, 600)
	Input.action_press("aim_up")
	await step(player)
	assert(not is_instance_valid(player.ladder), "Zero speed disables grabbing")
	Input.action_release("aim_up")
	Input.action_release("aim_up")
	player.settings.ladder_speed = 120
	player.position = Vector2(464, 600)
	player.reset_motion()
	await step(player)
	Input.action_press("aim_up")
	await step(player)
	assert(is_instance_valid(player.ladder))
	player.food_reel_locked = true
	await step(player)
	assert(not is_instance_valid(player.ladder) and player.get_collision_mask_value(4), "Food lock restores mask")
	player.food_reel_locked = false
	Input.action_release("aim_up")
	await step(player)
	Input.action_press("aim_up")
	await step(player)
	assert(is_instance_valid(player.ladder))
	stage.get_node("Ladder").queue_free()
	await process_frame
	await step(player)
	assert(not is_instance_valid(player.ladder) and player.get_collision_mask_value(4), "Deleted ladder restores mask")
	Input.action_release("aim_up")
	stage.queue_free()
	player.queue_free()
	await process_frame
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.player.position = Vector2(464, 600)
	Input.action_press("aim_up")
	await physics_frame
	game._physics_process(STEP)
	assert(is_instance_valid(game.player.ladder), "Game can grip")
	Input.action_press("gum_action")
	await physics_frame
	game._physics_process(STEP)
	assert(not is_instance_valid(game.player.ladder), "Actual Game X shot releases ladder")
	assert(game.player.get_collision_mask_value(4))
	Input.action_release("gum_action")
	Input.action_release("aim_up")
	game.queue_free()
	await process_frame
	print("Ladder verification PASS")
	quit()

extends Node2D
## Fixed-step owner: validate -> direction / actions -> gum -> player -> presentation.
const ContactPickup = preload("res://scripts/contact_pickup.gd")
const FoodCollectible = preload("res://scripts/food_collectible.gd")
const Settings = preload("res://scripts/game_settings.gd")
const TIME_ATTACK_RECORD := "user://time_attack_sprint.cfg"
const SPIKE_LAYER := 64
const RESPAWN_META := &"checkpoint_respawn"
var active_checkpoint: NodePath
@export var settings: Settings
@export var stage_scene: PackedScene
@export var stage_width := 5120
@export var fall_restart_offset := 0.0
@export var time_attack := false
var elapsed := 0.0
var best_time := 0.0
var timer_label: Label
var collected_items: Dictionary = {}
var score := 0
var cleared := false
var exit_door: Sprite2D
var entrance: Sprite2D
var pause_menu: CanvasLayer
var suppress_gameplay_tick := false
@onready var player: CharacterBody2D = $Player
@onready var player_shape: CollisionShape2D = $Player/CollisionShape2D
@onready var camera: Camera2D = $Camera2D
@onready var gum: Node2D = $Gum
var spike_sweep: ShapeCast2D
var restarting := false
var death_effect: Sprite2D
var aim_direction := Vector2.RIGHT
var up_wait_release := false
var down_wait_release := false
var manual_down_pressed := false

func _ready() -> void:
	_setup_stage()
	_setup_pickups()
	spike_sweep = ShapeCast2D.new()
	spike_sweep.shape = player_shape.shape
	spike_sweep.collision_mask = SPIKE_LAYER
	spike_sweep.collide_with_areas = true
	spike_sweep.collide_with_bodies = false
	spike_sweep.margin = 0.0
	spike_sweep.enabled = false
	add_child(spike_sweep)
	player.settings = settings
	gum.settings = settings
	player.global_position = $TheaterStage/PlacementMarkers/PlayerSpawn.global_position
	_setup_checkpoints()
	if time_attack:
		for prop in [$LightBox, $HeavyBox, $PuzzleLightBox, $PuzzleHeavyBox, $PulleyTrolley]:
			prop.free()
		_setup_timer()
	else:
		_setup_puzzle_props()
	gum.player = player
	player.gum = gum
	$GumAttachmentEffect.bind(gum)
	$GumShotParticles.bind(gum, settings)
	$GumHitParticles.bind(gum, settings)
	$GumHitShockwave.bind(gum, settings)
	$LandingDustEffect.bind(player)
	_setup_pause_menu()
	aim_direction = Vector2.LEFT if player.sprite.flip_h else Vector2.RIGHT
	camera.position = player.position
	camera.zoom = Vector2.ONE * settings.camera_normal_zoom
	_setup_entrance()
	_setup_exit()

func _setup_puzzle_props() -> void:
	$PuzzleLightBox.global_position = $TheaterStage/PlacementMarkers/LightBoxSpawn.global_position
	$PuzzleHeavyBox.global_position = $TheaterStage/PlacementMarkers/HeavyBoxSpawn.global_position
	$PulleyTrolley.bind(gum)

func _setup_timer() -> void:
	timer_label = $HUD/Timer
	timer_label.show()
	var record := ConfigFile.new()
	if record.load(TIME_ATTACK_RECORD) == OK:
		best_time = record.get_value("record", "seconds", 0.0)
	timer_label.text = "TIME %.2f" % elapsed

func _finish_time_attack() -> void:
	if best_time <= 0.0 or elapsed < best_time:
		best_time = elapsed
		var record := ConfigFile.new()
		record.set_value("record", "seconds", best_time)
		var error := record.save(TIME_ATTACK_RECORD)
		if error != OK:
			push_warning("Cannot save Time Attack record: %s" % error_string(error))
	timer_label.text = "TIME %.2f  |  BEST %.2f" % [elapsed, best_time]

func _setup_pickups() -> void:
	if get_tree().has_meta(RESPAWN_META):
		var saved: Dictionary = get_tree().get_meta(RESPAWN_META)
		if saved.get("scene") == scene_file_path:
			collected_items = saved.get("collected_items", {}).duplicate()
			score = saved.get("score", 0)
	$HUD/Score.text = "SCORE: %d" % score
	_register_pickups($TheaterStage)

func _register_pickups(host: Node) -> void:
	if host is TileMapLayer:
		host.update_internals()
	for child in host.get_children():
		if child is ContactPickup or child is FoodCollectible:
			# Capture the placed position before gum reeling can move the item.
			var key := "%s:%s" % [get_path_to(host), child.position]
			if collected_items.has(key):
				host.remove_child(child)
				child.queue_free()
				continue
			if child is FoodCollectible:
				child.collected.connect(func(_food_id: StringName):
					collected_items[key] = true
					_add_score(FoodCollectible.POINTS)
				)
			else:
				child.collected.connect(func(): collected_items[key] = true)
				child.collected.connect(_add_score.bind(child.points))
		else:
			_register_pickups(child)

func _add_score(points: int) -> void:
	score += points
	$HUD/Score.text = "SCORE %d" % score

func _setup_pause_menu() -> void:
	pause_menu = preload("res://scripts/pause_menu.gd").new()
	add_child(pause_menu)
	if time_attack:
		pause_menu.buttons[1].text = "モード選択に戻る"
	pause_menu.retry_requested.connect(restart)
	pause_menu.selection_requested.connect(return_to_stage_select)
	pause_menu.resumed.connect(func(): suppress_gameplay_tick = true)

func _setup_entrance() -> void:
	entrance = preload("res://scripts/stage_entrance.gd").new()
	entrance.name = "StageEntrance"
	add_child(entrance)
	move_child(entrance, player.get_index())
	var spawn: Vector2 = $TheaterStage/PlacementMarkers/PlayerSpawn.global_position
	entrance.global_position = _door_floor_position(spawn)
	if active_checkpoint.is_empty():
		player.global_position = entrance.global_position
		player.reset_motion()
		entrance.begin(player.sprite)
		gum.hide()
		camera.position = player.position

func _door_floor_position(marker_position: Vector2) -> Vector2:
	var query := PhysicsRayQueryParameters2D.create(marker_position - Vector2(0, 1), marker_position + Vector2(0, 64), 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else marker_position

func _setup_exit() -> void:
	exit_door = preload("res://scripts/stage_exit.gd").new()
	exit_door.name = "StageExit"
	add_child(exit_door)
	move_child(exit_door, player.get_index())
	exit_door.global_position = _door_floor_position($TheaterStage/PlacementMarkers/Exit.global_position)
	exit_door.player_entered.connect(_begin_exit)

func _begin_exit() -> void:
	if restarting or cleared or entrance.active or exit_door.started or is_instance_valid(death_effect):
		return
	if time_attack:
		_finish_time_attack()
	var vertical_speed: float = player.velocity.y
	gum.detach("STAGE EXIT")
	gum.hide()
	player.reset_motion()
	player.afterimages.clear()
	$LandingDustEffect.stop()
	exit_door.begin(player, vertical_speed)

func _setup_stage() -> void:
	if stage_scene != null:
		var old_stage := $TheaterStage
		remove_child(old_stage)
		old_stage.free()
		var selected_stage := stage_scene.instantiate()
		selected_stage.name = "TheaterStage"
		add_child(selected_stage)
	camera.limit_right = stage_width
	var prop_markers := {"LightBox": "EntranceLightBox", "HeavyBox": "EntranceHeavyBox", "PulleyTrolley": "PulleySpawn"}
	for prop in prop_markers:
		var placement := get_node_or_null("TheaterStage/PlacementMarkers/" + prop_markers[prop])
		if placement != null:
			get_node(prop).position = placement.position

func _physics_process(delta: float) -> void:
	if restarting:
		return
	if suppress_gameplay_tick:
		suppress_gameplay_tick = false
		return
	if Input.is_action_just_pressed("restart") and (time_attack or not cleared):
		restart()
		return
	if cleared:
		return
	if exit_door.active:
		player.reset_motion()
		exit_door.step(delta)
		if not player.sprite.visible and player.visible:
			player.hide()
			player.collision_layer = 0
			player.collision_mask = 0
		if not exit_door.active:
			_clear_stage()
		return
	if entrance.active:
		player.reset_motion()
		entrance.step(delta)
		up_wait_release = Input.is_action_pressed("aim_up")
		down_wait_release = Input.is_action_pressed("aim_down")
		if not entrance.active:
			gum.show()
		return
	if time_attack:
		elapsed += delta
		timer_label.text = "TIME: %.2f" % elapsed
	if is_instance_valid(death_effect):
		if death_effect.step(delta):
			restart(true)
		return
	if player.position.y > settings.restart_y + fall_restart_offset:
		SoundEffects.play(&"dead")
		restart(true)
		return
	var previous_shape_transform: Transform2D = player_shape.global_transform
	if _touches_spikes(previous_shape_transform, Vector2.ZERO):
		_die_on_spikes(previous_shape_transform.origin)
		return
	gum.validate_connection()
	var was_reeling: bool = gum.reeling_food()
	var jump_requested := Input.is_action_just_pressed("jump") and not was_reeling
	var attached_jump: bool = jump_requested and gum.connected() and not was_reeling
	_update_direction()
	var length_input := _read_length_input(jump_requested)
	_handle_actions(jump_requested)
	gum.step(delta, length_input)
	player.food_reel_locked = was_reeling or gum.reeling_food()
	player.simulate(delta, jump_requested, attached_jump)
	var movement: Vector2 = player_shape.global_position - previous_shape_transform.origin
	if _touches_spikes(previous_shape_transform, movement):
		_die_on_spikes(previous_shape_transform.origin + movement * spike_sweep.get_closest_collision_safe_fraction())
		return
	_update_camera(delta)
	gum.update_aim(_aim_target())

func _setup_checkpoints() -> void:
	var checkpoints := get_node_or_null("TheaterStage/Checkpoints")
	if checkpoints != null:
		for checkpoint in checkpoints.get_children():
			checkpoint.reached.connect(_on_checkpoint_reached)
	if not get_tree().has_meta(RESPAWN_META):
		return
	var saved: Dictionary = get_tree().get_meta(RESPAWN_META)
	get_tree().remove_meta(RESPAWN_META)
	if saved.get("scene") != scene_file_path:
		return
	if time_attack:
		elapsed = saved.get("elapsed", 0.0)
	var checkpoint = get_node_or_null(saved.get("checkpoint", NodePath()))
	if checkpoint != null and checkpoint.get_parent() == checkpoints:
		active_checkpoint = get_path_to(checkpoint)
		checkpoint.activate(false)
		player.global_position = checkpoint.respawn_position()

func _on_checkpoint_reached(checkpoint: Area2D) -> void:
	if restarting or exit_door.started or is_instance_valid(death_effect):
		return
	if not checkpoint.activated:
		SoundEffects.play(&"checkpoint")
	active_checkpoint = get_path_to(checkpoint)
	checkpoint.activate()

func _die_on_spikes(center: Vector2) -> void:
	if restarting or exit_door.started or is_instance_valid(death_effect):
		return
	SoundEffects.play(&"dead")
	gum.detach("SPIKES")
	gum.hide()
	player.hide()
	player.afterimages.clear()
	$LandingDustEffect.stop()
	death_effect = preload("res://scripts/player_disappear_effect.gd").new()
	add_child(death_effect)
	death_effect.global_position = center
	camera.global_position = center - player_shape.position

func restart(from_checkpoint := false) -> void:
	if restarting:
		return
	restarting = true
	pause_menu.close()
	if from_checkpoint and (time_attack or not active_checkpoint.is_empty()):
		get_tree().set_meta(RESPAWN_META, {
			"scene": scene_file_path, "checkpoint": active_checkpoint, "elapsed": elapsed,
			"collected_items": collected_items.duplicate(), "score": score,
		})
	elif get_tree().has_meta(RESPAWN_META):
		get_tree().remove_meta(RESPAWN_META)
	gum.detach("RESTART")
	$LandingDustEffect.stop()
	$GumShotParticles.stop()
	$GumHitParticles.stop()
	$GumHitShockwave.stop()
	get_tree().call_deferred("reload_current_scene")

func _touches_spikes(start: Transform2D, movement: Vector2) -> bool:
	spike_sweep.global_transform = start
	spike_sweep.target_position = start.basis_xform_inv(movement)
	spike_sweep.force_shapecast_update()
	return spike_sweep.is_colliding()

func _update_camera(delta: float) -> void:
	camera.position = player.position
	var target_zoom: float = settings.camera_normal_zoom
	if gum.connected():
		var start: float = settings.camera_gum_zoom_start
		var end: float = settings.camera_gum_zoom_end
		# Equal/reversed thresholds become a step, avoiding division by zero.
		var weight := float(gum.path.length >= start)
		if end > start:
			weight = clampf((gum.path.length - start) / (end - start), 0.0, 1.0)
		target_zoom = minf(target_zoom, lerpf(settings.camera_normal_zoom, settings.camera_long_gum_zoom, weight))
	var blend := 1.0 - exp(-settings.camera_zoom_response * delta) if settings.camera_zoom_response > 0.0 else 1.0
	camera.zoom = camera.zoom.lerp(Vector2.ONE * target_zoom, blend)

func _aim_target() -> Vector2:
	return gum.origin() + aim_direction * gum.settings.attachment_range

func _read_length_input(jump_requested: bool) -> float:
	var up := Input.is_action_pressed("aim_up")
	var down := Input.is_action_pressed("aim_down")
	up_wait_release = up_wait_release and up
	down_wait_release = down_wait_release and down
	manual_down_pressed = false
	if not gum.connected() or jump_requested:
		up_wait_release = up
		down_wait_release = down
		return 0.0
	manual_down_pressed = down and not down_wait_release
	if manual_down_pressed:
		gum.relax()
	return float(manual_down_pressed) - float(up and not up_wait_release)

func _update_direction() -> void:
	# Quantize keyboard/pad input to eight directions; neutral preserves the last direction.
	var direction := Vector2(Input.get_axis("aim_left", "aim_right"), Input.get_axis("aim_up", "aim_down"))
	if not direction.is_zero_approx():
		aim_direction = direction.sign().normalized()

func _handle_actions(jump_requested: bool) -> void:
	if gum.reeling_food():
		return
	if jump_requested:
		gum.detach()
		return
	if not Input.is_action_just_pressed("gum_action"):
		return
	if gum.connected():
		if not manual_down_pressed:
			gum.contract()
	elif gum.state != gum.State.OUTBOUND:
		gum.fire(aim_direction)
		player.fire_gum()

func return_to_stage_select() -> void:
	if restarting:
		return
	restarting = true
	pause_menu.close()
	if get_tree().has_meta(RESPAWN_META):
		get_tree().remove_meta(RESPAWN_META)
	gum.detach("STAGE SELECT")
	var selection := "mode_select" if time_attack else "stage_select"
	get_tree().call_deferred("change_scene_to_file", "res://scenes/%s.tscn" % selection)

func _clear_stage() -> void:
	cleared = true
	gum.detach("STAGE CLEAR")
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$HUD.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 200)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	panel.add_child(column)
	var title := Label.new()
	title.text = "TIME %.2f  /  BEST %.2f" % [elapsed, best_time] if time_attack else "STAGE CLEAR!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	column.add_child(title)
	if time_attack:
		var retry := Button.new()
		retry.text = "リトライ"
		retry.custom_minimum_size.y = 64
		column.add_child(retry)
		retry.pressed.connect(restart)
		retry.grab_focus()
		return
	var back := Button.new()
	back.text = "ステージ選択へ"
	back.custom_minimum_size.y = 64
	column.add_child(back)
	back.pressed.connect(return_to_stage_select)
	back.grab_focus()

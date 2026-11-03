extends Node2D
## Fixed-step owner: validate -> direction / actions -> gum -> player -> presentation.
const Settings = preload("res://scripts/game_settings.gd")
const SPIKE_LAYER := 64
const RESPAWN_META := &"checkpoint_respawn"
var active_checkpoint: NodePath
@export var settings: Settings
@onready var player: CharacterBody2D = $Player
@onready var player_shape: CollisionShape2D = $Player/CollisionShape2D
@onready var camera: Camera2D = $Camera2D
@onready var gum: Node2D = $Gum
@onready var status: Label = $HUD/Status
var spike_sweep: ShapeCast2D
var restarting := false
var death_effect: Sprite2D
var aim_direction := Vector2.RIGHT
var up_wait_release := false
var down_wait_release := false
var manual_down_pressed := false

func _ready() -> void:
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
	$PuzzleLightBox.global_position = $TheaterStage/PlacementMarkers/LightBoxSpawn.global_position
	$PuzzleHeavyBox.global_position = $TheaterStage/PlacementMarkers/HeavyBoxSpawn.global_position
	gum.player = player
	player.gum = gum
	$PulleyTrolley.bind(gum)
	$GumAttachmentEffect.bind(gum)
	$GumShotParticles.bind(gum, settings)
	$GumHitParticles.bind(gum, settings)
	$GumHitShockwave.bind(gum, settings)
	$LandingDustEffect.bind(player)
	aim_direction = Vector2.LEFT if player.sprite.flip_h else Vector2.RIGHT
	camera.position = player.position
	camera.zoom = Vector2.ONE * settings.camera_normal_zoom

func _physics_process(delta: float) -> void:
	if restarting:
		return
	if Input.is_action_just_pressed("restart"):
		restart()
		return
	if is_instance_valid(death_effect):
		if death_effect.step(delta):
			restart(true)
		return
	if player.position.y > settings.restart_y:
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
	_update_status()

func _setup_checkpoints() -> void:
	for checkpoint in $TheaterStage/Checkpoints.get_children():
		checkpoint.reached.connect(_on_checkpoint_reached)
	if not get_tree().has_meta(RESPAWN_META):
		return
	var saved: Dictionary = get_tree().get_meta(RESPAWN_META)
	get_tree().remove_meta(RESPAWN_META)
	if saved.get("scene") != scene_file_path:
		return
	var checkpoint = get_node_or_null(saved.get("checkpoint", NodePath()))
	if checkpoint != null and checkpoint.get_parent() == $TheaterStage/Checkpoints:
		active_checkpoint = get_path_to(checkpoint)
		checkpoint.activate(false)
		player.global_position = checkpoint.respawn_position()

func _on_checkpoint_reached(checkpoint: Area2D) -> void:
	if restarting or is_instance_valid(death_effect):
		return
	if not checkpoint.activated:
		SoundEffects.play(&"checkpoint")
	active_checkpoint = get_path_to(checkpoint)
	checkpoint.activate()

func _die_on_spikes(center: Vector2) -> void:
	if restarting or is_instance_valid(death_effect):
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
	if from_checkpoint and not active_checkpoint.is_empty() and has_node(active_checkpoint):
		get_tree().set_meta(RESPAWN_META, {"scene": scene_file_path, "checkpoint": active_checkpoint})
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

func _update_status() -> void:
	if gum.connected():
		status.text = "%s | TENSION %d%% | LENGTH %.0f / REST %.0f | LIMIT %.0f%% | PIVOTS %d" % [
			"CONTRACT" if gum.mode == gum.Mode.CONTRACT else "LOOSEN",
			gum.tension / gum.settings.maximum_tension * 100.0,
			gum.path.length, gum.rest_length,
			gum.path.length / gum.settings.maximum_length * 100.0, gum.path.pivots.size()]
	else:
		var phase: String = gum.release_reason
		if gum.state == gum.State.OUTBOUND:
			phase = "FLYING"
		elif gum.state == gum.State.RETURNING:
			phase = "RETURNING"
		status.text = "%s | %s" % [phase, "TARGET" if gum.aim_valid else "NO TARGET"]

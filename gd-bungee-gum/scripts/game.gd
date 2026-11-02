extends Node2D
## Fixed-step owner: validate -> direction / actions -> gum -> player -> presentation.
const Settings = preload("res://scripts/game_settings.gd")
@export var settings: Settings
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var gum: Node2D = $Gum
@onready var status: Label = $HUD/Status
var restarting := false
var aim_direction := Vector2.RIGHT
var up_wait_release := false
var down_wait_release := false
var manual_down_pressed := false

func _ready() -> void:
	player.settings = settings
	gum.settings = settings
	player.global_position = $TheaterStage/PlacementMarkers/PlayerSpawn.global_position
	$PuzzleLightBox.global_position = $TheaterStage/PlacementMarkers/LightBoxSpawn.global_position
	$PuzzleHeavyBox.global_position = $TheaterStage/PlacementMarkers/HeavyBoxSpawn.global_position
	gum.player = player
	player.gum = gum
	$GumAttachmentEffect.bind(gum)
	aim_direction = Vector2.LEFT if player.sprite.flip_h else Vector2.RIGHT
	camera.position = player.position
	camera.zoom = Vector2.ONE * settings.camera_normal_zoom

func _physics_process(delta: float) -> void:
	if restarting:
		return
	if Input.is_action_just_pressed("restart") or player.position.y > settings.restart_y:
		restarting = true
		gum.detach("RESTART")
		get_tree().call_deferred("reload_current_scene")
		return
	gum.validate_connection()
	var jump_requested := Input.is_action_just_pressed("jump")
	var attached_jump: bool = jump_requested and gum.connected()
	_update_direction()
	var length_input := _read_length_input(jump_requested)
	_handle_actions(jump_requested)
	gum.step(delta, length_input)
	player.simulate(delta, jump_requested, attached_jump)
	_update_camera(delta)
	gum.update_aim(_aim_target())
	_update_status()

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

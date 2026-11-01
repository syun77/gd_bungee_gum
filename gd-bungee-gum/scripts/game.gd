extends Node2D
## Fixed-step owner: validate -> manual controls / Z/X gesture -> spring -> player -> presentation.
const Settings = preload("res://scripts/game_settings.gd")
@export var settings: Settings
enum Gesture { IDLE, AIM, WAIT_RELEASE }
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var gum: Node2D = $Gum
@onready var status: Label = $HUD/Status
var restarting := false
var gesture := Gesture.IDLE
var aim_direction := Vector2.RIGHT
var aim_selected := false
var camera_hold_time := 0.0
var camera_was_connected := false
var up_wait_release := false
var down_wait_release := false
var manual_down_pressed := false

func _ready() -> void:
	player.settings = settings
	gum.settings = settings
	player.global_position = $TheaterStage/PlacementMarkers/PlayerSpawn.global_position
	gum.player = player
	player.gum = gum
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
	var was_connected: bool = gum.connected()
	gum.validate_connection()
	var jump_requested := Input.is_action_just_pressed("jump")
	var length_input := _read_length_input(jump_requested)
	_handle_gesture(jump_requested)
	gum.step(delta, length_input)
	if was_connected and not gum.connected():
		player.cancel_gum_action()
	player.simulate(delta, gesture == Gesture.AIM, jump_requested)
	_update_camera(delta)
	gum.aiming = gesture == Gesture.AIM
	gum.update_aim(_aim_target())
	_update_status()

func _update_camera(delta: float) -> void:
	camera.position = player.position
	var connected: bool = gum.connected()
	var hold_zoom := not connected and Input.is_action_pressed("gum_action")
	if connected != camera_was_connected:
		camera_hold_time = 0.0
	else:
		camera_hold_time = camera_hold_time + delta if hold_zoom else 0.0
	camera_was_connected = connected
	var target_zoom: float = settings.camera_normal_zoom
	if hold_zoom and camera_hold_time >= settings.camera_hold_delay:
		target_zoom = minf(target_zoom, settings.camera_hold_zoom)
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
	return gum.origin() + aim_direction * gum.settings.maximum_length

func _read_length_input(jump_requested: bool) -> float:
	var up := Input.is_action_pressed("aim_up")
	var down := Input.is_action_pressed("aim_down")
	up_wait_release = up_wait_release and up
	down_wait_release = down_wait_release and down
	manual_down_pressed = false
	if not gum.connected() or jump_requested:
		up_wait_release = false
		down_wait_release = false
		return 0.0
	manual_down_pressed = down and not down_wait_release
	if manual_down_pressed:
		gum.relax()
	return float(manual_down_pressed) - float(up and not up_wait_release)

func _handle_gesture(jump_requested: bool) -> void:
	# WAIT_RELEASE consumes the remainder of an attached/cancel gesture, even if the
	# connection breaks while X is held. A release must never turn into a new shot.
	if jump_requested:
		gum.detach()
		up_wait_release = false
		down_wait_release = false
		player.cancel_gum_action()
		gesture = Gesture.WAIT_RELEASE if Input.is_action_pressed("gum_action") else Gesture.IDLE
		return
	if gesture == Gesture.WAIT_RELEASE:
		if not Input.is_action_pressed("gum_action"):
			gesture = Gesture.IDLE
		return
	if Input.is_action_just_pressed("gum_action"):
		if gum.connected():
			if not manual_down_pressed:
				gum.contract()
			gesture = Gesture.WAIT_RELEASE
		else:
			if not aim_selected:
				aim_direction = Vector2.LEFT if player.sprite.flip_h else Vector2.RIGHT
				aim_selected = true
			gesture = Gesture.AIM
	if gesture != Gesture.AIM:
		return
	# Opposing directions cancel per axis; a zero vector preserves the last aim.
	var direction := Vector2(Input.get_axis("aim_left", "aim_right"), Input.get_axis("aim_up", "aim_down"))
	if direction != Vector2.ZERO:
		aim_direction = direction.normalized()
	player.face_aim(aim_direction)
	if Input.is_action_just_released("gum_action"):
		if gum.attach_at(_aim_target()):
			up_wait_release = Input.is_action_pressed("aim_up")
			down_wait_release = Input.is_action_pressed("aim_down")
		player.fire_gum()
		gesture = Gesture.IDLE

func _update_status() -> void:
	if gum.connected():
		status.text = "%s | TENSION %d%% | LENGTH %.0f / REST %.0f | LIMIT %.0f%% | PIVOTS %d" % [
			"CONTRACT" if gum.mode == gum.Mode.CONTRACT else "LOOSEN",
			gum.tension / gum.settings.maximum_tension * 100.0,
			gum.path.length, gum.rest_length,
			gum.path.length / gum.settings.maximum_length * 100.0, gum.path.pivots.size()]
	else:
		status.text = "%s | %s" % ["AIM" if gesture == Gesture.AIM else gum.release_reason,
			"TARGET" if gum.aim_valid else "NO TARGET"]

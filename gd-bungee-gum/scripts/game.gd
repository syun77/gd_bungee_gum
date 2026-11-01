extends Node2D
## Fixed-step owner: validate -> Z/X gesture -> spring -> player -> presentation.
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

func _ready() -> void:
	player.settings = settings
	gum.settings = settings
	player.global_position = $TheaterStage/PlacementMarkers/PlayerSpawn.global_position
	gum.player = player
	player.gum = gum
	aim_direction = Vector2.LEFT if player.sprite.flip_h else Vector2.RIGHT
	camera.position = player.position

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
	_handle_gesture(jump_requested)
	gum.step(delta)
	if was_connected and not gum.connected():
		player.cancel_gum_action()
	player.simulate(delta, gesture == Gesture.AIM, jump_requested)
	camera.position = player.position
	gum.aiming = gesture == Gesture.AIM
	gum.update_aim(_aim_target())
	_update_status()

func _aim_target() -> Vector2:
	return gum.origin() + aim_direction * gum.settings.maximum_length

func _handle_gesture(jump_requested: bool) -> void:
	# WAIT_RELEASE consumes the remainder of a toggle/cancel gesture, even if the
	# connection breaks while X is held. A release must never turn into a new shot.
	if jump_requested:
		gum.detach()
		player.cancel_gum_action()
		gesture = Gesture.WAIT_RELEASE if Input.is_action_pressed("gum_action") else Gesture.IDLE
		return
	if gesture == Gesture.WAIT_RELEASE:
		if not Input.is_action_pressed("gum_action"):
			gesture = Gesture.IDLE
		return
	if Input.is_action_just_pressed("gum_action"):
		if gum.connected():
			gum.toggle_mode()
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
		gum.attach_at(_aim_target())
		player.fire_gum()
		gesture = Gesture.IDLE

func _update_status() -> void:
	if gum.connected():
		status.text = "%s | TENSION %d%% | LENGTH %.0f / REST %.0f | LIMIT %.0f%%" % [
			"CONTRACT" if gum.mode == gum.Mode.CONTRACT else "LOOSEN",
			gum.tension / gum.settings.maximum_tension * 100.0,
			gum.origin().distance_to(gum.endpoint()), gum.rest_length,
			gum.origin().distance_to(gum.endpoint()) / gum.settings.maximum_length * 100.0]
	else:
		status.text = "%s | %s" % ["AIM" if gesture == Gesture.AIM else gum.release_reason,
			"TARGET" if gum.aim_valid else "NO TARGET"]

extends Node2D
## Single fixed-step owner: input -> spring forces -> player collision -> presentation.
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var gum: Node2D = $Gum
@onready var status: Label = $HUD/Status
var restarting := false

func _ready() -> void:
	player.global_position = $TheaterStage/PlacementMarkers/PlayerSpawn.global_position
	gum.player = player
	player.gum = gum
	camera.position = player.position

func _physics_process(delta: float) -> void:
	if restarting:
		return
	if Input.is_action_just_pressed("restart") or player.position.y > 900.0:
		restarting = true
		gum.detach("RESTART")
		get_tree().call_deferred("reload_current_scene")
		return
	var was_connected: bool = gum.connected()
	var aim := get_global_mouse_position()
	if Input.is_action_just_pressed("gum_detach"):
		gum.detach()
	elif Input.is_action_just_pressed("gum_attach"):
		gum.attach_at(aim)
		player.fire_gum()
	gum.step(delta, Input.is_action_pressed("gum_contract"))
	if was_connected and not gum.connected():
		player.cancel_gum_action()
	player.simulate(delta)
	camera.position = player.position
	gum.update_aim(aim)
	_update_status()

func _update_status() -> void:
	if gum.connected():
		status.text = "%s | TENSION %d%% | LENGTH %.0f / REST %.0f | LIMIT %.0f%%" % [
			"CONTRACTING" if gum.contracting else "ATTACHED",
			gum.tension / gum.settings.maximum_tension * 100.0,
			gum.origin().distance_to(gum.endpoint()), gum.rest_length,
			gum.origin().distance_to(gum.endpoint()) / gum.settings.maximum_length * 100.0]
	else:
		status.text = "%s | %s" % [gum.release_reason, "AIM: ATTACHABLE" if gum.aim_valid else "AIM: NO TARGET"]

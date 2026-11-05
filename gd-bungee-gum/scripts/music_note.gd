extends "res://scripts/contact_pickup.gd"
## Player-contact pickup with a quiet highlight and a broad, shallow vertical-axis turn.

const HIGHLIGHT_PERIOD := 3.0
const HIGHLIGHT_DURATION := 0.6
const TURN_PERIOD := 4.0
const MAX_YAW := deg_to_rad(32.0)
var highlight_elapsed := 0.0
var turn_elapsed := 0.0
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# Each placed note owns its uniform; stable position phases avoid synchronized rows.
	sprite.material = sprite.material.duplicate()
	super()
	var phase := global_position.dot(Vector2(0.7548777, 0.5698403))
	highlight_elapsed = fposmod(phase, HIGHLIGHT_PERIOD)
	turn_elapsed = fposmod(phase, TURN_PERIOD)
	_update_appearance()

func _process(delta: float) -> void:
	highlight_elapsed = fposmod(highlight_elapsed + delta, HIGHLIGHT_PERIOD)
	turn_elapsed = fposmod(turn_elapsed + delta, TURN_PERIOD)
	_update_appearance()

func _update_appearance() -> void:
	var progress := clampf((highlight_elapsed - (HIGHLIGHT_PERIOD - HIGHLIGHT_DURATION)) / HIGHLIGHT_DURATION, 0.0, 1.0)
	var strength := pow(sin(progress * PI), 2.0)
	var appearance := sprite.material as ShaderMaterial
	appearance.set_shader_parameter("shine", strength)
	appearance.set_shader_parameter("yaw", sin(turn_elapsed / TURN_PERIOD * TAU) * MAX_YAW)

extends Area2D
## Player-contact pickup with a quiet highlight and a broad, shallow vertical-axis turn.
signal collected

const PERIOD := 3.0
const SHINE_DURATION := 0.6
const TURN_PERIOD := 4.0
const MAX_YAW := deg_to_rad(32.0)
var is_collected := false
var elapsed := 0.0
var turn_elapsed := 0.0
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# Each placed note owns its uniform; stable position phases avoid synchronized rows.
	sprite.material = sprite.material.duplicate()
	body_entered.connect(_on_body_entered)
	var phase := global_position.dot(Vector2(0.7548777, 0.5698403))
	elapsed = fposmod(phase, PERIOD)
	turn_elapsed = fposmod(phase, TURN_PERIOD)
	_update_appearance()

func _process(delta: float) -> void:
	elapsed = fposmod(elapsed + delta, PERIOD)
	turn_elapsed = fposmod(turn_elapsed + delta, TURN_PERIOD)
	_update_appearance()

func _update_appearance() -> void:
	var progress := clampf((elapsed - (PERIOD - SHINE_DURATION)) / SHINE_DURATION, 0.0, 1.0)
	var strength := pow(sin(progress * PI), 2.0)
	var appearance := sprite.material as ShaderMaterial
	appearance.set_shader_parameter("shine", strength)
	appearance.set_shader_parameter("yaw", sin(turn_elapsed / TURN_PERIOD * TAU) * MAX_YAW)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect()

func collect() -> void:
	if is_collected:
		return
	is_collected = true
	hide()
	set_process(false)
	get_node("/root/SoundEffects").play(&"item")
	collected.emit()
	queue_free()

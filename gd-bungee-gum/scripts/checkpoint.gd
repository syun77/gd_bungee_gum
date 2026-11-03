@tool
extends Area2D
## Feet-origin checkpoint. Activation is owned by Game; art never affects collision.
signal reached(checkpoint: Area2D)
@export var respawn_offset := Vector2(0, -2)
var activated := false
var elapsed := 0.0
const FRAME_SECONDS := 0.055
# Opaque base bottom in each atlas cell; excludes the transparent padding.
const FRAME_BASELINES := [396.0, 396.0, 396.0, 396.0, 389.5, 389.5, 389.5, 390.5]
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.frame_changed.connect(_align_artwork)
	_align_artwork()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
	set_process(false)

func _align_artwork() -> void:
	var cell_height := sprite.texture.get_height() / float(sprite.vframes)
	sprite.position.y = -(FRAME_BASELINES[sprite.frame] - cell_height * 0.5) * sprite.scale.y

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		reached.emit(self)

func activate(animate := true) -> void:
	if activated:
		return
	activated = true
	elapsed = 0.0
	sprite.frame = 0 if animate else sprite.hframes * sprite.vframes - 1
	set_process(animate)
	$Effect.activate(animate)

func _process(delta: float) -> void:
	elapsed += delta
	var last_frame := sprite.hframes * sprite.vframes - 1
	sprite.frame = mini(int(elapsed / FRAME_SECONDS), last_frame)
	if sprite.frame == last_frame:
		set_process(false)

func respawn_position() -> Vector2:
	return global_position + respawn_offset

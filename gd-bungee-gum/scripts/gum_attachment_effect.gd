extends Sprite2D
## Presentation follows the live adhesion point without inheriting target scale.
const SURFACE = preload("res://assets/effects/gum_attach_surface.png")
const RING = preload("res://assets/effects/gum_attach_ring.png")
const FPS := 30.0
const VISIBLE_FRAMES := 9
var gum: Node2D
var elapsed := 0.0
var radial := false
var local_tangent := Vector2.ZERO

func bind(connection: Node2D) -> void:
	gum = connection
	gum.adhesion_started.connect(_start)
	gum.adhesion_ended.connect(_stop)

func _start(normal: Vector2, is_ring: bool) -> void:
	radial = is_ring
	texture = RING if radial else SURFACE
	var tangent := Vector2(-normal.y, normal.x)
	local_tangent = gum.target.global_transform.basis_xform_inv(tangent)
	elapsed = 0.0
	frame = 0
	visible = true
	_follow_endpoint()

func _stop() -> void:
	visible = false

func _process(delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(gum) or not gum.connected():
		_stop()
		return
	elapsed += delta
	if elapsed >= VISIBLE_FRAMES / FPS:
		_stop()
		return
	frame = int(elapsed * FPS)
	_follow_endpoint()

func _follow_endpoint() -> void:
	global_position = gum.endpoint()
	var tangent: Vector2 = gum.target.global_transform.basis_xform(local_tangent)
	global_rotation = 0.0 if radial else Vector2.LEFT.angle_to(tangent.orthogonal())

extends CharacterBody2D
## Feet-origin controller. Game calls simulate() once after gum forces each physics tick.
const GUM_HANDS := {
	&"gum_fire": [Vector2(180, 143), Vector2(176, 142), Vector2(185, 140), Vector2(196, 135), Vector2(207, 122), Vector2(216, 123), Vector2(214, 123), Vector2(211, 123)],
	&"gum_pull": [Vector2(220, 109), Vector2(216, 109), Vector2(217, 109), Vector2(218, 110), Vector2(220, 106), Vector2(217, 106), Vector2(217, 104), Vector2(219, 102)],
	&"gum_hang": [Vector2(171, 40), Vector2(171, 40), Vector2(171, 40), Vector2(173, 40), Vector2(171, 40), Vector2(171, 40), Vector2(171, 40), Vector2(172, 40)],
}


@export var run_speed := 220.0
@export var ground_acceleration := 1600.0
@export var air_acceleration := 350.0
@export var gravity := 1100.0
@export var kick_speed := 260.0
@export_range(0.01, 1000.0) var mass := 1.0
var external_velocity := Vector2.ZERO
var control_velocity := Vector2.ZERO
var kick_available := true
var landing_time := 0.0
var gum: Node2D
var fire_time := 0.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	var poses: SpriteFrames = preload("res://assets/characters/teto/gum_animations.tres")
	sprite.sprite_frames = sprite.sprite_frames.duplicate()
	for animation in poses.get_animation_names():
		sprite.sprite_frames.add_animation(animation)
		sprite.sprite_frames.set_animation_speed(animation, poses.get_animation_speed(animation))
		sprite.sprite_frames.set_animation_loop(animation, poses.get_animation_loop(animation))
		for index in poses.get_frame_count(animation):
			sprite.sprite_frames.add_frame(animation, poses.get_frame_texture(animation, index), poses.get_frame_duration(animation, index))

func face_aim(direction: Vector2) -> void:
	if direction.x != 0.0:
		sprite.flip_h = direction.x < 0.0

func fire_gum() -> void:
	fire_time = 8.0 / 12.0
	sprite.stop()
	sprite.play("gum_fire")

func cancel_gum_action() -> void:
	fire_time = 0.0

func gum_visual_origin() -> Vector2:
	# Drawing-only hand samples in the 256px cells; physical attachment stays at chest.
	var hands: Array = GUM_HANDS.get(sprite.animation, [])
	if hands.is_empty():
		return global_position + Vector2(-12 if sprite.flip_h else 12, -34)
	var offset: Vector2 = hands[sprite.frame] - Vector2(128, 128)
	if sprite.flip_h:
		offset.x = -offset.x
	return sprite.to_global(offset)

func apply_external_force(force: Vector2, delta: float) -> void:
	external_velocity += force / mass * delta

func simulate(delta: float, aiming := false, jump_requested := false) -> void:
	# 接触判定は直前の move_and_slide() の結果。今回の移動後に更新される。
	var grounded := is_on_floor()
	var touching := grounded or is_on_wall() or is_on_ceiling()
	if not touching:
		kick_available = true
	# project.godot の物理キー割り当てを使用。A／左矢印=-1、D／右矢印=+1。
	var direction := 0.0 if aiming else Input.get_axis("move_left", "move_right")
	var acceleration := ground_acceleration if grounded else air_acceleration
	# 入力を離しても減速し、反対入力でも即反転しない。地上では最高速から停止まで
	# 約0.14秒、逆方向の最高速までは約0.28秒。空中では約0.63秒／1.26秒。
	control_velocity.x = move_toward(control_velocity.x, direction * run_speed, acceleration * delta)
	external_velocity.y += gravity * delta
	if jump_requested and touching and kick_available:
		var normal := get_floor_normal() if grounded else (get_wall_normal() if is_on_wall() else Vector2.DOWN)
		external_velocity += normal * kick_speed
		kick_available = false
	# 左右入力が変更するのは control_velocity のみ。外部の横速度に摩擦はなく、
	# 無入力でも滑り続ける。外部速度+300、左入力-220なら右へ約80 px/sで進む。
	velocity = control_velocity + external_velocity
	move_and_slide()
	# 衝突面へ向かう成分を両速度から除去する。床の法線に微小な横成分がある場合、
	# slide() により外部横速度にも微小値が生じる（実測で約0.02 px/s）。
	for index in get_slide_collision_count():
		var normal := get_slide_collision(index).get_normal()
		if external_velocity.dot(normal) < 0.0:
			external_velocity = external_velocity.slide(normal)
		if control_velocity.dot(normal) < 0.0:
			control_velocity = control_velocity.slide(normal)
	velocity = control_velocity + external_velocity
	if not grounded and is_on_floor():
		landing_time = 0.12
	landing_time = maxf(landing_time - delta, 0.0)
	fire_time = maxf(fire_time - delta, 0.0)
	_update_animation(direction)

func _update_animation(direction: float) -> void:
	# 絵の左右向きは実速度ではなく入力に即追従する。方向転換の減速中や
	# 外部速度で流されているときは、向きと実際の進行方向が逆になる。
	if direction != 0.0:
		sprite.flip_h = direction < 0.0
	if is_instance_valid(gum) and (fire_time > 0.0 or gum.connected()):
		var aim: Vector2 = (gum.endpoint() if gum.connected() else gum.aim_point) - gum.origin()
		sprite.flip_h = aim.x < 0.0
		if fire_time > 0.0:
			sprite.play("gum_fire")
			return
		if not is_on_floor() and gum.tension > 10.0:
			var above: bool = gum.endpoint().y < gum.origin().y - 40.0
			sprite.play("gum_hang" if above and velocity.length() < 130.0 else "gum_pull")
			return
	if not is_on_floor():
		sprite.play("jump")
		sprite.pause()
		sprite.frame = 2 if velocity.y < -80.0 else (3 if velocity.y < 80.0 else 5)
	elif landing_time > 0.0:
		sprite.play("jump")
		sprite.pause()
		sprite.frame = 6
	else:
		sprite.play("run" if absf(velocity.x) > 12.0 else "idle")

extends CharacterBody2D
## Feet-origin controller. External momentum persists independently of steering.

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
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func apply_external_force(force: Vector2, delta: float) -> void:
	external_velocity += force / mass * delta

func _physics_process(delta: float) -> void:
	# 接触判定は直前の move_and_slide() の結果。今回の移動後に更新される。
	var grounded := is_on_floor()
	var touching := grounded or is_on_wall() or is_on_ceiling()
	if not touching:
		kick_available = true
	# project.godot の物理キー割り当てを使用。A／左矢印=-1、D／右矢印=+1。
	var direction := Input.get_axis("move_left", "move_right")
	var acceleration := ground_acceleration if grounded else air_acceleration
	# 入力を離しても減速し、反対入力でも即反転しない。地上では最高速から停止まで
	# 約0.14秒、逆方向の最高速までは約0.28秒。空中では約0.63秒／1.26秒。
	control_velocity.x = move_toward(control_velocity.x, direction * run_speed, acceleration * delta)
	external_velocity.y += gravity * delta
	if Input.is_action_just_pressed("kick_off") and touching and kick_available:
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
	_update_animation(direction)

func _update_animation(direction: float) -> void:
	# 絵の左右向きは実速度ではなく入力に即追従する。方向転換の減速中や
	# 外部速度で流されているときは、向きと実際の進行方向が逆になる。
	if direction != 0.0:
		sprite.flip_h = direction < 0.0
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

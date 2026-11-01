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
	var grounded := is_on_floor()
	var touching := grounded or is_on_wall() or is_on_ceiling()
	if not touching:
		kick_available = true
	var direction := Input.get_axis("move_left", "move_right")
	var acceleration := ground_acceleration if grounded else air_acceleration
	control_velocity.x = move_toward(control_velocity.x, direction * run_speed, acceleration * delta)
	external_velocity.y += gravity * delta
	if Input.is_action_just_pressed("kick_off") and touching and kick_available:
		var normal := get_floor_normal() if grounded else (get_wall_normal() if is_on_wall() else Vector2.DOWN)
		external_velocity += normal * kick_speed
		kick_available = false
	velocity = control_velocity + external_velocity
	move_and_slide()
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

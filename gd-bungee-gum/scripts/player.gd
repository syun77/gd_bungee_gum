extends CharacterBody2D
## Feet-origin controller. Game calls simulate() once after gum forces each physics tick.
const GUM_HANDS := {
	&"gum_fire": [Vector2(180, 143), Vector2(176, 142), Vector2(185, 140), Vector2(196, 135), Vector2(207, 122), Vector2(216, 123), Vector2(214, 123), Vector2(211, 123)],
	&"gum_pull": [Vector2(220, 109), Vector2(216, 109), Vector2(217, 109), Vector2(218, 110), Vector2(220, 106), Vector2(217, 106), Vector2(217, 104), Vector2(219, 102)],
	&"gum_hang": [Vector2(171, 40), Vector2(171, 40), Vector2(171, 40), Vector2(173, 40), Vector2(171, 40), Vector2(171, 40), Vector2(171, 40), Vector2(172, 40)],
}


const Settings = preload("res://scripts/game_settings.gd")
@export var settings: Settings
var external_velocity := Vector2.ZERO
var control_velocity := Vector2.ZERO
var kick_available := true
var coyote_remaining := 0.0
var coyote_normal := Vector2.UP
var coyote_gravity_velocity := Vector2.ZERO
var landing_time := 0.0
var gum: Node2D
var fire_time := 0.0
var landing_diagnostic_active := false
var landing_diagnostic_next_tick := 0
var landing_diagnostic_transitions := 0
var landing_diagnostic_details := 0
var landing_diagnostic_next_impact_tick := 0
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
	external_velocity += force / settings.player_mass * delta

func simulate(delta: float, aiming := false, jump_requested := false) -> void:
	# 接触判定は直前の move_and_slide() の結果。今回の移動後に更新される。
	var grounded := is_on_floor()
	var touching := grounded or is_on_wall() or is_on_ceiling()
	if grounded:
		coyote_remaining = settings.coyote_time
		coyote_normal = get_floor_normal()
		coyote_gravity_velocity = Vector2.ZERO
	else:
		coyote_remaining = maxf(minf(coyote_remaining, settings.coyote_time) - delta, 0.0)
	if coyote_remaining <= 0.0:
		coyote_gravity_velocity = Vector2.ZERO
	# Floor contact restores a kick even when wall contact never broke.
	if grounded or not touching:
		if not kick_available:
			_log_jump_state("REARMED")
		kick_available = true
	# project.godot の物理キー割り当てを使用。A／左矢印=-1、D／右矢印=+1。
	var direction := 0.0 if aiming else Input.get_axis("move_left", "move_right")
	var acceleration := settings.ground_acceleration if grounded else settings.air_acceleration
	# 入力速度は設定の加速度で目標速度へ近づけ、無入力ではゼロへ減速する。
	var removed_control_y := control_velocity.y
	control_velocity = Vector2(move_toward(control_velocity.x, direction * settings.run_speed, acceleration * delta), 0.0)
	var gravity_velocity := Vector2(0.0, settings.gravity * delta)
	external_velocity += gravity_velocity
	if coyote_remaining > 0.0:
		coyote_gravity_velocity += gravity_velocity
	var coyote_kick := not touching and coyote_remaining > 0.0
	var can_kick := kick_available and (touching or coyote_kick)
	if jump_requested:
		var result := "REJECTED_NO_CONTACT" if not touching else "REJECTED_NOT_REARMED"
		if can_kick:
			result = "ACCEPTED_COYOTE" if coyote_kick else "ACCEPTED"
		_log_jump_state(result)
	if jump_requested and can_kick:
		var normal := coyote_normal
		if touching:
			normal = get_floor_normal() if grounded else (get_wall_normal() if is_on_wall() else Vector2.DOWN)
		if coyote_kick:
			var falling_speed := maxf(-external_velocity.dot(normal), 0.0)
			var gravity_fall := maxf(-coyote_gravity_velocity.dot(normal), 0.0)
			external_velocity += normal * minf(falling_speed, gravity_fall)
		external_velocity += normal * settings.kick_speed
		kick_available = false
		coyote_remaining = 0.0
		coyote_gravity_velocity = Vector2.ZERO
	# 外部速度は空中で保持し、接地後に床面方向の摩擦で減速する。
	velocity = control_velocity + external_velocity
	var incoming_velocity := velocity
	move_and_slide()
	# 衝突面へ向かう成分を両速度から除去する。床の法線に微小な横成分がある場合、
	# slide() により外部横速度にも微小値が生じる（実測で約0.02 px/s）。
	for index in get_slide_collision_count():
		var normal := get_slide_collision(index).get_normal()
		# Gravity already resolved by terrain must not remain available as compensation.
		if coyote_gravity_velocity.dot(normal) < 0.0:
			coyote_gravity_velocity = coyote_gravity_velocity.slide(normal)
		if external_velocity.dot(normal) < 0.0:
			external_velocity = external_velocity.slide(normal)
		if control_velocity.dot(normal) < 0.0:
			var projected_control := control_velocity.slide(normal)
			if absf(projected_control.y) > absf(removed_control_y):
				removed_control_y = projected_control.y
			# Input intent stays horizontal; collision momentum belongs to external_velocity.
			control_velocity.x = projected_control.x
	_apply_ground_friction(delta)
	velocity = control_velocity + external_velocity
	if not grounded and is_on_floor():
		landing_time = 0.12
	landing_time = maxf(landing_time - delta, 0.0)
	fire_time = maxf(fire_time - delta, 0.0)
	_update_animation(direction)
	if jump_requested:
		_log_jump_state("AFTER_MOVE", incoming_velocity)
	_log_landing_state(grounded, incoming_velocity, removed_control_y)

func _log_jump_state(event: String, incoming := Vector2.ZERO) -> void:
	if not settings.jump_diagnostics:
		return
	var normals: Array[Vector2] = []
	for index in get_slide_collision_count():
		normals.append(get_slide_collision(index).get_normal())
	var attached: bool = is_instance_valid(gum) and gum.connected()
	print("[JumpDiagnostic] %s tick=%d feet=%s floor=%s wall=%s ceiling=%s available=%s z_held=%s x_held=%s control=%s external=%s incoming=%s normals=%s gum=%s coyote=%.3f" % [
		event, Engine.get_physics_frames(), global_position, is_on_floor(), is_on_wall(), is_on_ceiling(),
		kick_available, Input.is_action_pressed("jump"), Input.is_action_pressed("gum_action"),
		control_velocity, external_velocity, incoming, normals, attached, coyote_remaining])

func _apply_ground_friction(delta: float) -> void:
	if not is_on_floor():
		return
	var normal := get_floor_normal()
	var tangent := normal.orthogonal()
	var speed := external_velocity.dot(tangent)
	external_velocity += tangent * (move_toward(speed, 0.0, settings.ground_friction * delta) - speed)

func _update_animation(direction: float) -> void:
	# 絵の左右向きは実速度ではなく入力に即追従する。方向転換の減速中や
	# 外部速度で流されているときは、向きと実際の進行方向が逆になる。
	if direction != 0.0:
		sprite.flip_h = direction < 0.0
	if is_instance_valid(gum) and (fire_time > 0.0 or gum.connected()):
		var aim: Vector2 = gum.support_point() - gum.origin()
		sprite.flip_h = aim.x < 0.0
		if fire_time > 0.0:
			sprite.play("gum_fire")
			return
		if not is_on_floor() and gum.tension > 10.0:
			var above: bool = gum.support_point().y < gum.origin().y - 40.0
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

func _log_landing_state(was_grounded: bool, incoming_velocity: Vector2, removed_control_y: float) -> void:
	if not settings.landing_diagnostics:
		landing_diagnostic_active = false
		return
	var unexpected_vertical := absf(control_velocity.y) > 1.0
	var event := ""
	var tick := Engine.get_physics_frames()
	if unexpected_vertical and not landing_diagnostic_active:
		landing_diagnostic_active = true
		landing_diagnostic_transitions = 0
		landing_diagnostic_details = 0
		landing_diagnostic_next_tick = tick + 60
		event = "VERTICAL_CONTROL_DETECTED"
	elif landing_diagnostic_active:
		if was_grounded != is_on_floor():
			landing_diagnostic_transitions += 1
			if landing_diagnostic_details < 6:
				landing_diagnostic_details += 1
				event = "LANDED" if is_on_floor() else "LEFT_FLOOR"
		if not unexpected_vertical:
			landing_diagnostic_active = false
			event = "CLEARED"
		elif tick >= landing_diagnostic_next_tick:
			event = "PERSISTING"
			landing_diagnostic_next_tick = tick + 60
	if event.is_empty() and tick >= landing_diagnostic_next_impact_tick:
		if absf(removed_control_y) > 1.0:
			event = "CONTROL_COLLISION_RESOLVED"
		elif not was_grounded and is_on_floor() and incoming_velocity.length() > 300.0:
			event = "HIGH_SPEED_LANDING"
		if not event.is_empty():
			landing_diagnostic_next_impact_tick = tick + 30
	if event.is_empty():
		return
	var normals: Array[Vector2] = []
	for i in get_slide_collision_count():
		normals.append(get_slide_collision(i).get_normal())
	var attached: bool = is_instance_valid(gum) and gum.connected()
	var gum_status: String = gum.release_reason if is_instance_valid(gum) else "NO GUM"
	var gum_tension: float = gum.tension if attached else 0.0
	print("[LandingDiagnostic] %s tick=%d feet=%s control=%s external=%s floor=%s->%s transitions=%d animation=%s landing=%.3f fire=%.3f gum=%s reason=%s tension=%.1f incoming=%s removed_control_y=%.3f normals=%s" % [
		event, tick, global_position, control_velocity, external_velocity,
		was_grounded, is_on_floor(), landing_diagnostic_transitions,
		sprite.animation, landing_time, fire_time, attached, gum_status, gum_tension, incoming_velocity, removed_control_y, normals])

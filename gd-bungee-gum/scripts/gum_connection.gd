extends Node2D
## Rules own the connection; physics resolves both endpoints' motion.
const Settings = preload("res://scripts/gum_settings.gd")
enum Mode { NONE, CONTRACT, LOOSEN }
@export var settings: Settings
var player: CharacterBody2D
var target: PhysicsBody2D
var target_local_point := Vector2.ZERO
var rest_length := 0.0
var tension := 0.0
var player_force := Vector2.ZERO
var target_force := Vector2.ZERO
var aim_point := Vector2.ZERO
var aim_valid := false
var release_reason := "READY"
var mode := Mode.NONE
var aiming := false

func origin() -> Vector2:
	return player.global_position + Vector2(0, -34)

func connected() -> bool:
	return is_instance_valid(target) and not target.is_queued_for_deletion()

func endpoint() -> Vector2:
	return target.to_global(target_local_point) if connected() else origin()

func cast_to(point: Vector2) -> Dictionary:
	var offset := point - origin()
	if offset.length_squared() < 0.01:
		return {}
	var end := origin() + offset.limit_length(settings.maximum_length)
	var query := PhysicsRayQueryParameters2D.create(origin(), end, 1 | 4, [player.get_rid()])
	query.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(query)

func attachable(hit: Dictionary) -> bool:
	if hit.is_empty():
		return false
	var body = hit.collider
	return (body is StaticBody2D or body is RigidBody2D) and not body.is_in_group("gum_blocked")

func attach_at(point: Vector2) -> bool:
	# A miss keeps the existing connection; a successful shot replaces it atomically.
	var hit := cast_to(point)
	if not attachable(hit):
		return false
	target = hit.collider
	target_local_point = target.to_local(hit.position)
	rest_length = origin().distance_to(hit.position)
	tension = 0.0
	player_force = Vector2.ZERO
	target_force = Vector2.ZERO
	mode = Mode.CONTRACT
	release_reason = "ATTACHED"
	return true

func detach(reason := "RELEASED") -> void:
	# Never alter either endpoint's velocity on release.
	target = null
	tension = 0.0
	player_force = Vector2.ZERO
	target_force = Vector2.ZERO
	mode = Mode.NONE
	release_reason = reason

func target_point_velocity() -> Vector2:
	if target is RigidBody2D:
		var body := target as RigidBody2D
		var radius := endpoint() - body.to_global(body.center_of_mass)
		return body.linear_velocity + Vector2(-radius.y, radius.x) * body.angular_velocity
	return Vector2.ZERO

func validate_connection() -> void:
	if not connected():
		if target != null or mode != Mode.NONE:
			detach("TARGET LOST")
		return
	var offset := endpoint() - origin()
	if offset.length() > settings.maximum_length:
		detach("TOO FAR")
	elif offset.length() > 4.0 and not cast_to(endpoint() - offset.normalized() * 3.0).is_empty():
		detach("OBSTRUCTED")

func toggle_mode() -> void:
	if not connected():
		return
	if mode == Mode.CONTRACT:
		mode = Mode.LOOSEN
		rest_length = minf(settings.maximum_length, maxf(rest_length, origin().distance_to(endpoint()) + settings.loosen_margin))
	else:
		mode = Mode.CONTRACT

func step(delta: float) -> void:
	player_force = Vector2.ZERO
	target_force = Vector2.ZERO
	tension = 0.0
	validate_connection()
	if not connected():
		return
	var offset := endpoint() - origin()
	var distance := offset.length()
	if mode == Mode.CONTRACT:
		# A shot closer than minimum_length must not lengthen on contraction.
		rest_length = maxf(minf(rest_length, settings.minimum_length), rest_length - settings.contraction_speed * delta)
	if distance <= rest_length or distance < 0.01:
		return
	var direction := offset / distance
	var separation_speed := (target_point_velocity() - player.velocity).dot(direction)
	tension = clampf(settings.stiffness * (distance - rest_length) + settings.damping * separation_speed, 0.0, settings.maximum_tension)
	player_force = direction * tension
	target_force = -player_force
	player.apply_external_force(player_force, delta)
	if target is RigidBody2D:
		# apply_force takes force (not impulse) and a world-oriented offset from origin.
		(target as RigidBody2D).apply_force(target_force, endpoint() - target.global_position)

func update_aim(point: Vector2) -> void:
	var hit := cast_to(point)
	aim_valid = attachable(hit)
	aim_point = hit.position if not hit.is_empty() else origin() + (point - origin()).limit_length(settings.maximum_length)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(player):
		return
	var start := to_local(player.gum_visual_origin())
	var aim := to_local(aim_point)
	var aim_color := Color(0.45, 1.0, 0.75, 0.8) if aim_valid else Color(1, 0.7, 0.6, 0.6)
	if aiming:
		draw_dashed_line(start, aim, Color(aim_color, 0.25), 1.0, 6.0)
		draw_arc(aim, 7.0, 0, TAU, 20, aim_color, 1.5)
	if not connected():
		return
	var end := to_local(endpoint())
	var ratio := tension / settings.maximum_tension
	var color := Color(1, 0.52, 0.8).lerp(Color(1, 0.2, 0.28), ratio)
	var sag := minf(maxf(rest_length - start.distance_to(end), 0.0) * 0.35, 70.0)
	var points := PackedVector2Array()
	for index in 25:
		var weight := index / 24.0
		points.append(start.lerp(end, weight) + Vector2(0, sin(weight * PI) * sag))
	draw_polyline(points, color, 2.0 + ratio * 4.0, true)
	draw_circle(end, 5.0, color)

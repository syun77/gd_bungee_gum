extends Node2D
## Rules own the connection; physics resolves both endpoints' motion.
const Settings = preload("res://scripts/game_settings.gd")
const GumPath = preload("res://scripts/gum_path.gd")
var path = GumPath.new()
var terrain_forces := PackedVector2Array()
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

func support_point() -> Vector2:
	return path.points[1] if connected() and path.points.size() > 1 else aim_point

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
	path.reset(origin(), hit.position)
	rest_length = path.length
	terrain_forces.clear()
	tension = 0.0
	player_force = Vector2.ZERO
	target_force = Vector2.ZERO
	mode = Mode.CONTRACT
	release_reason = "ATTACHED"
	return true

func detach(reason := "RELEASED") -> void:
	# Never alter either endpoint's velocity on release.
	target = null
	path.initialized = false
	path.pivots.clear()
	path.points.clear()
	path.length = 0.0
	terrain_forces.clear()
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

func toggle_mode() -> void:
	if not connected():
		return
	if mode == Mode.CONTRACT:
		mode = Mode.LOOSEN
		if not path.update(origin(), endpoint(), get_tree().root, settings, false):
			detach(path.failure)
			return
		rest_length = minf(settings.maximum_length, maxf(rest_length, path.length + settings.loosen_margin))
	else:
		mode = Mode.CONTRACT

func step(delta: float) -> void:
	player_force = Vector2.ZERO
	target_force = Vector2.ZERO
	tension = 0.0
	terrain_forces.clear()
	validate_connection()
	if not connected():
		return
	if not path.update(origin(), endpoint(), get_tree().root, settings):
		detach(path.failure)
		return
	if path.length > settings.maximum_length:
		detach("TOO FAR")
		return
	if _dynamic_obstruction():
		detach("UNSUPPORTED OBSTACLE")
		return
	var distance: float = path.length
	if mode == Mode.CONTRACT:
		# A shot closer than minimum_length must not lengthen on contraction.
		rest_length = maxf(minf(rest_length, settings.minimum_length), rest_length - settings.contraction_speed * delta)
	if distance <= rest_length or distance < 0.01:
		return
	var direction: Vector2 = path.start_direction()
	var separation_speed: float = path.speed(player.velocity, target_point_velocity())
	tension = clampf(settings.stiffness * (distance - rest_length) + settings.damping * separation_speed, 0.0, settings.maximum_tension)
	player_force = direction * tension
	target_force = -path.end_direction() * tension
	terrain_forces = path.reactions(tension)
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
	var aim_color := settings.aim_valid_color if aim_valid else settings.aim_invalid_color
	if aiming:
		draw_dashed_line(start, aim, aim_color, settings.aim_line_width, settings.aim_dash_length)
		draw_arc(aim, settings.aim_reticle_radius, 0, TAU, 20, aim_color, settings.aim_reticle_width)
	if not connected():
		return
	var ratio := tension / settings.maximum_tension
	var color := settings.gum_slack_color.lerp(settings.gum_taut_color, ratio)
	var points := _display_points()
	if points.size() > 1:
		draw_polyline(points, color, settings.gum_line_width + ratio * settings.gum_tension_width, true)
	for pivot in path.pivots:
		draw_circle(to_local(pivot.position), 3.0, color)
	draw_circle(to_local(endpoint()), 5.0, color)

func _display_points() -> PackedVector2Array:
	var result := PackedVector2Array()
	if path.points.size() < 2:
		return result
	var slack: float = maxf(rest_length - path.length, 0.0)
	for i in range(path.points.size()-1):
		var a: Vector2 = player.gum_visual_origin() if i == 0 else path.points[i]
		var b: Vector2 = endpoint() if i == path.points.size()-2 else path.points[i+1]
		var sag := minf(slack * a.distance_to(b) / maxf(path.length, 0.01) * 0.35, 70.0)
		var curve := PackedVector2Array()
		for attempt in 5:
			curve = PackedVector2Array([a])
			var clear := true
			for sample in range(1,25):
				var weight := sample / 24.0
				var point := a.lerp(b,weight) + Vector2(0,sin(weight*PI)*sag)
				if not path.geometry.visible(curve[-1],point):
					clear = false
				curve.append(point)
			if clear:
				break
			sag *= 0.5
			if attempt == 4:
				curve = PackedVector2Array([a,b])
		for j in range(0 if i == 0 else 1,curve.size()):
			result.append(to_local(curve[j]))
	return result

func _dynamic_obstruction() -> bool:
	for i in range(path.points.size()-1):
		var a: Vector2 = path.points[i]
		var b: Vector2 = path.points[i+1]
		var end := b
		if i == path.points.size()-2:
			end = b.move_toward(a, minf(0.1, a.distance_to(b)*0.1))
		var query := PhysicsRayQueryParameters2D.create(a, end, 4, [player.get_rid()])
		query.hit_from_inside = true
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			return true
	return false

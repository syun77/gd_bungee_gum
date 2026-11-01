extends Node2D
## Rules own the connection; physics resolves both endpoints' motion.
const Settings = preload("res://scripts/game_settings.gd")
const GumPath = preload("res://scripts/gum_path.gd")
var path = GumPath.new()
var terrain_forces := PackedVector2Array()
enum Mode { NONE, CONTRACT, LOOSEN }
enum State { READY, OUTBOUND, ATTACHED, RETURNING }
var state := State.READY
var tip := Vector2.ZERO
var shot_direction := Vector2.RIGHT
var shot_distance := 0.0
var return_points := PackedVector2Array()
var return_time := 0.0
var last_display := PackedVector2Array()
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

func origin() -> Vector2:
	return player.global_position + Vector2(0, -34)

func connected() -> bool:
	return is_instance_valid(target) and not target.is_queued_for_deletion()

func endpoint() -> Vector2:
	return target.to_global(target_local_point) if connected() else tip

func support_point() -> Vector2:
	return path.points[1] if connected() and path.points.size() > 1 else (tip if state == State.OUTBOUND else aim_point)

func cast_to(point: Vector2) -> Dictionary:
	var offset := point - origin()
	if offset.length_squared() < 0.01:
		return {}
	var end := origin() + offset.limit_length(settings.attachment_range)
	return _cast_segment(origin(), end)

func _cast_segment(start: Vector2, end: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(start, end, 1 | 4, [player.get_rid()])
	query.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(query)

func attachable(hit: Dictionary) -> bool:
	if hit.is_empty():
		return false
	var body = hit.collider
	return (body is StaticBody2D or body is RigidBody2D) and not body.is_in_group("gum_blocked") and origin().distance_to(hit.position) <= settings.maximum_length

func attach_at(point: Vector2) -> bool:
	# Direct connection setup for physics fixtures; gameplay fires a moving tip.
	var hit := cast_to(point)
	if not attachable(hit):
		return false
	_attach_hit(hit)
	return true

func _attach_hit(hit: Dictionary) -> void:
	state = State.ATTACHED
	return_points.clear()
	last_display.clear()
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
	last_display = PackedVector2Array([player.gum_visual_origin(), hit.position])

func fire(direction: Vector2) -> void:
	if connected() or state == State.OUTBOUND or direction.is_zero_approx():
		return
	cancel_return()
	state = State.OUTBOUND
	tip = origin()
	shot_direction = direction.normalized()
	shot_distance = 0.0
	release_reason = "FLYING"

func cancel_return() -> void:
	if state == State.RETURNING:
		state = State.READY
	return_points.clear()
	last_display.clear()

func _step_outbound(delta: float) -> void:
	var travel := minf(settings.gum_shot_speed * delta, settings.attachment_range - shot_distance)
	var next := tip + shot_direction * travel
	var hit := _cast_segment(tip, next)
	tip = hit.position if not hit.is_empty() else next
	shot_distance += travel
	if origin().distance_to(tip) > settings.maximum_length:
		detach("TOO FAR")
		return
	# The root may have moved since firing. Reject lines obstructed behind the tip.
	var root_hit := _cast_segment(origin(), tip.move_toward(origin(), 0.1))
	if not root_hit.is_empty():
		detach("BLOCKED PATH")
		return
	if not hit.is_empty():
		if attachable(hit):
			_attach_hit(hit)
		else:
			detach("BLOCKED")
	elif shot_distance >= settings.attachment_range:
		detach("MISS")

func _step_return(delta: float) -> void:
	return_time += delta
	if return_points.size() > 0:
		return_points[0] = player.gum_visual_origin()
	var remaining := settings.gum_return_speed * delta
	while return_points.size() > 1 and remaining > 0.0:
		var index := return_points.size() - 1
		var distance := return_points[index].distance_to(return_points[index - 1])
		if remaining >= distance:
			remaining -= distance
			return_points.remove_at(index)
		else:
			return_points[index] = return_points[index].move_toward(return_points[index - 1], remaining)
			remaining = 0.0
	if return_points.size() <= 1 or return_time >= settings.gum_return_max_duration:
		cancel_return()
	else:
		tip = return_points[-1]

func detach(reason := "RELEASED") -> void:
	if reason == "RESTART":
		cancel_return()
		state = State.READY
	elif state == State.ATTACHED or state == State.OUTBOUND:
		if connected() and reason == "RELEASED":
			return_points = _world_display_points()
		elif state == State.OUTBOUND:
			return_points = PackedVector2Array([player.gum_visual_origin(), tip])
		else:
			return_points = last_display.duplicate()
		state = State.RETURNING
		return_time = 0.0
		if return_points.size() > 0:
			tip = return_points[-1]
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

func relax() -> void:
	if connected():
		mode = Mode.LOOSEN

func contract() -> void:
	if connected():
		mode = Mode.CONTRACT

func manual_length_limit() -> float:
	return clampf(settings.maximum_length - settings.manual_length_margin, 0.0, settings.maximum_length)

func _shorten(speed: float, delta: float) -> void:
	# A short-range attachment must never lengthen in response to shortening.
	rest_length = maxf(minf(rest_length, settings.minimum_length), rest_length - speed * delta)

func step(delta: float, length_input := 0.0) -> void:
	player_force = Vector2.ZERO
	target_force = Vector2.ZERO
	tension = 0.0
	terrain_forces.clear()
	validate_connection()
	if state == State.OUTBOUND:
		_step_outbound(delta)
		return
	if state == State.RETURNING:
		_step_return(delta)
		return
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
	last_display = _world_display_points()
	var distance: float = path.length
	if mode == Mode.CONTRACT:
		_shorten(settings.contraction_speed, delta)
	elif length_input > 0.0:
		# Above-cap attachments hold their length rather than snapping shorter.
		rest_length = maxf(rest_length, minf(manual_length_limit(), rest_length + settings.manual_extension_speed * delta))
	elif length_input < 0.0:
		_shorten(settings.manual_shortening_speed, delta)
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
	aim_point = hit.position if not hit.is_empty() else origin() + (point - origin()).limit_length(settings.attachment_range)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(player):
		return
	if state == State.READY:
		var start := to_local(player.gum_visual_origin())
		var aim := to_local(aim_point)
		var aim_color := settings.aim_valid_color if aim_valid else settings.aim_invalid_color
		aim_color.a *= settings.aim_guide_opacity
		draw_dashed_line(start, aim, aim_color, settings.aim_line_width, settings.aim_dash_length)
		draw_arc(aim, settings.aim_reticle_radius, 0, TAU, 20, aim_color, settings.aim_reticle_width)
		return
	var ratio := tension / settings.maximum_tension
	var color := settings.gum_slack_color.lerp(settings.gum_taut_color, ratio)
	if mode == Mode.LOOSEN:
		color = settings.gum_loosen_color
	var points := _display_points()
	var width := settings.gum_line_width + ratio * settings.gum_tension_width
	# Wide translucent layers soften the silhouette without screen-wide bloom.
	if settings.gum_glow_radius > 0.0 and settings.gum_glow_opacity > 0.0:
		for layer in range(4, 0, -1):
			var spread := settings.gum_glow_radius * layer / 4.0
			var halo := Color(color, color.a * settings.gum_glow_opacity * (5.0 - layer) / 4.0)
			_draw_gum_shape(points, halo, width, spread)
	_draw_gum_shape(points, color, width, 0.0)
	var core := color.lerp(Color(1.0, 1.0, 1.0, color.a), settings.gum_core_brightness)
	_draw_gum_shape(points, core, maxf(1.0, width * 0.35), 0.0, 0.4)

func _draw_gum_shape(points: PackedVector2Array, color: Color, width: float, spread: float, marker_scale: float = 1.0) -> void:
	if points.size() > 1:
		draw_polyline(points, color, width + spread * 2.0, true)
	for pivot in path.pivots:
		draw_circle(to_local(pivot.position), 3.0 * marker_scale + spread, color, true, -1.0, true)
	draw_circle(to_local(endpoint()), 5.0 * marker_scale + spread, color, true, -1.0, true)

func _world_display_points() -> PackedVector2Array:
	var points := _display_points()
	for i in points.size():
		points[i] = to_global(points[i])
	return points

func _display_points() -> PackedVector2Array:
	var result := PackedVector2Array()
	if state == State.OUTBOUND:
		return PackedVector2Array([to_local(player.gum_visual_origin()), to_local(tip)])
	if state == State.RETURNING:
		for point in return_points:
			result.append(to_local(point))
		if not result.is_empty():
			result[0] = to_local(player.gum_visual_origin())
		return result
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

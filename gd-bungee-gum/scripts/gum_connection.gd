extends Node2D
## Rules own the connection; physics resolves both endpoints' motion.
signal adhesion_started(normal: Vector2, is_ring: bool)
signal shot_started
signal shot_advanced(start: Vector2, end: Vector2)
signal adhesion_ended

const Food = preload("res://scripts/food_collectible.gd")
const Settings = preload("res://scripts/game_settings.gd")
const RIGID_CONTACT_TOLERANCE := 2.0
const AIM_TILE_BLINK_HZ := 3.0
const GumPath = preload("res://scripts/gum_path.gd")
var contraction_sound_pending := false
var path = GumPath.new()
var terrain_forces := PackedVector2Array()
enum Mode { NONE, CONTRACT, LOOSEN }
enum State { READY, OUTBOUND, ATTACHED, RETURNING, REELING }
var state := State.READY
var tip := Vector2.ZERO
var shot_direction := Vector2.RIGHT
var shot_distance := 0.0
var return_points := PackedVector2Array()
var return_time := 0.0
var last_display := PackedVector2Array()
@export var settings: Settings
var player: CharacterBody2D
var target: Node2D
var target_rid := RID()
var target_local_point := Vector2.ZERO
var rest_length := 0.0
var tension := 0.0
var player_force := Vector2.ZERO
var target_force := Vector2.ZERO
var aim_point := Vector2.ZERO
var aim_valid := false
var aim_tile_polygon := PackedVector2Array()
var aim_blink_time := 0.0
var release_reason := "READY"
var mode := Mode.NONE
var diagnostic_history: Array[Dictionary] = []
var diagnostic_obstruction: Dictionary = {}
var glow_canvas: Node2D

func _ready() -> void:
	glow_canvas = Node2D.new()
	glow_canvas.name = "GumBloom"
	glow_canvas.show_behind_parent = true
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow_canvas.material = additive
	glow_canvas.draw.connect(_draw_glow)
	add_child(glow_canvas)

func _draw_glow() -> void:
	if not is_instance_valid(player) or state == State.READY:
		return
	if settings.gum_glow_radius <= 0.0 or settings.gum_glow_opacity <= 0.0:
		return
	var ratio := tension / settings.maximum_tension
	var color := _gum_color(ratio)
	var points := _display_points()
	var width := settings.gum_line_width + ratio * settings.gum_tension_width
	# Gaussian falloff keeps the bright inner halo soft at its outer edge.
	for layer in range(24, 0, -1):
		var fraction := float(layer) / 24.0
		var halo := Color(color, color.a * settings.gum_glow_opacity * exp(-4.5 * fraction * fraction) / 6.0)
		_draw_gum_shape(glow_canvas, points, halo, width, settings.gum_glow_radius * fraction)

func _gum_color(ratio: float) -> Color:
	return settings.gum_loosen_color if mode == Mode.LOOSEN else settings.gum_slack_color.lerp(settings.gum_taut_color, ratio)

func origin() -> Vector2:
	return player.global_position + Vector2(0, -34)

func connected() -> bool:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return false
	if target is TileMapLayer:
		return target.collision_enabled and target.has_body_rid(target_rid)
	return true

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

func _cast_segment(start: Vector2, end: Vector2, excluded_rid: RID = RID()) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(start, end, 1 | 4 | 16 | 32, [player.get_rid()])
	if excluded_rid.is_valid():
		query.exclude = query.exclude + [excluded_rid]
	query.collide_with_areas = true
	query.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(query)

func attachable(hit: Dictionary) -> bool:
	if hit.is_empty():
		return false
	var body = hit.collider
	var supported: bool = body is StaticBody2D or body is RigidBody2D or (body is Food and not body.is_collected)
	if body is TileMapLayer:
		supported = body.has_body_rid(hit.rid) and (PhysicsServer2D.body_get_collision_layer(hit.rid) & 16) != 0
	return supported and not body.is_in_group("gum_blocked") and origin().distance_to(_attachment_point(hit)) <= settings.maximum_length

func _attachment_point(hit: Dictionary) -> Vector2:
	var body = hit.collider
	if body is Food:
		return body.global_position
	if body is TileMapLayer:
		# The generous hit area extends outside the cell; the RID owns its identity.
		return body.to_global(body.map_to_local(body.get_coords_for_body_rid(hit.rid)))
	return hit.position

func attach_at(point: Vector2) -> bool:
	# Direct connection setup for physics fixtures; gameplay fires a moving tip.
	var hit := cast_to(point)
	if not attachable(hit):
		return false
	_attach_hit(hit)
	return true

func _attach_hit(hit: Dictionary) -> void:
	state = State.ATTACHED
	diagnostic_history.clear()
	diagnostic_obstruction.clear()
	return_points.clear()
	last_display.clear()
	target = hit.collider
	target_rid = hit.rid
	var point := _attachment_point(hit)
	target_local_point = target.to_local(point)
	tip = point
	path.reset(origin(), point)
	rest_length = path.length
	terrain_forces.clear()
	tension = 0.0
	player_force = Vector2.ZERO
	target_force = Vector2.ZERO
	mode = Mode.CONTRACT
	contraction_sound_pending = true
	release_reason = "ATTACHED"
	last_display = PackedVector2Array([player.gum_visual_origin(), point])
	var normal: Vector2 = hit.get("normal", Vector2.ZERO)
	if normal.is_zero_approx():
		normal = (origin() - point).normalized()
	if target is Food:
		state = State.REELING
		target.being_pulled = true
		player.reset_motion()
	else:
		player.on_gum_attached()
	SoundEffects.play(&"hit")
	adhesion_started.emit(normal, target is TileMapLayer)

func reeling_food() -> bool:
	return state == State.REELING and connected()

func _step_food_reel(delta: float) -> void:
	var food: Food = target
	var hand: Vector2 = player.gum_visual_origin()
	food.global_position = food.global_position.move_toward(hand, settings.food_reel_speed * delta)
	target_local_point = Vector2.ZERO
	path.reset(origin(), food.global_position)
	rest_length = path.length
	last_display = PackedVector2Array([hand, food.global_position])
	if food.global_position.distance_to(hand) <= 0.01:
		food.collect()
		player.food_jump_available = true
		detach("FOOD COLLECTED")
		cancel_return()

func fire(direction: Vector2) -> void:
	if connected() or state == State.OUTBOUND or direction.is_zero_approx():
		return
	cancel_return()
	diagnostic_history.clear()
	diagnostic_obstruction.clear()
	state = State.OUTBOUND
	tip = origin()
	shot_direction = direction.normalized()
	shot_distance = 0.0
	release_reason = "FLYING"
	SoundEffects.play(&"shoot")
	shot_started.emit()

func cancel_return() -> void:
	if state == State.RETURNING:
		state = State.READY
	return_points.clear()
	last_display.clear()

func _step_outbound(delta: float) -> void:
	var travel := minf(settings.gum_shot_speed * delta, settings.attachment_range - shot_distance)
	var previous_tip := tip
	var next := tip + shot_direction * travel
	var hit := _cast_segment(tip, next)
	tip = hit.position if not hit.is_empty() else next
	shot_advanced.emit(previous_tip, tip)
	shot_distance += travel
	if origin().distance_to(tip) > settings.maximum_length:
		detach("TOO FAR")
		return
	# The root may have moved since firing. Reject lines obstructed behind the tip.
	# The hit ring is an adhesion target, including when the shot starts inside it.
	var hit_anchor_rid: RID = hit.rid if hit.get("collider") is TileMapLayer else RID()
	var root_hit := _cast_segment(origin(), tip.move_toward(origin(), 0.1), hit_anchor_rid)
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
	if settings.gum_diagnostics and state in [State.ATTACHED, State.OUTBOUND]:
		print("[GumDiagnostic] DETACH reason=", reason, " snapshot=", _diagnostic_snapshot(), " obstruction=", diagnostic_obstruction)
		for snapshot in diagnostic_history:
			print("[GumDiagnostic] HISTORY ", snapshot)
	if reason == "RESTART":
		cancel_return()
		state = State.READY
	elif state in [State.ATTACHED, State.OUTBOUND, State.REELING]:
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
	if is_instance_valid(target) and target is Food:
		target.being_pulled = false
	# Never alter either endpoint's velocity on release.
	target = null
	target_rid = RID()
	path.initialized = false
	path.pivots.clear()
	path.points.clear()
	path.length = 0.0
	terrain_forces.clear()
	tension = 0.0
	player_force = Vector2.ZERO
	target_force = Vector2.ZERO
	mode = Mode.NONE
	contraction_sound_pending = false
	release_reason = reason
	adhesion_ended.emit()

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
		contraction_sound_pending = false

func contract() -> void:
	if connected() and mode != Mode.CONTRACT:
		mode = Mode.CONTRACT
		contraction_sound_pending = true

func _play_contraction_sound() -> void:
	if contraction_sound_pending:
		contraction_sound_pending = false
		SoundEffects.play(&"pull")

func manual_length_limit() -> float:
	return clampf(settings.maximum_length - settings.manual_length_margin, 0.0, settings.maximum_length)

func _shorten(speed: float, delta: float) -> void:
	# A short-range attachment must never lengthen in response to shortening.
	rest_length = maxf(minf(rest_length, settings.minimum_length), rest_length - speed * delta)

func _diagnostic_snapshot() -> Dictionary:
	var snapshot := {
		"tick": Engine.get_physics_frames(), "state": State.keys()[state],
		"mode": Mode.keys()[mode], "origin": origin(), "endpoint": endpoint(),
		"player_velocity": player.velocity, "player_external_velocity": player.external_velocity,
		"target_valid": connected(), "path_length": path.length, "rest_length": rest_length,
		"maximum_length": settings.maximum_length, "tension": tension,
		"player_force": player_force, "target_force": target_force,
		"route_endpoint": path.points[-1] if not path.points.is_empty() else endpoint(),
		"points": path.points.duplicate(), "pivots": path.pivots.size(),
		"path_failure": path.failure, "path_repairs": path.modifications,
		"previous_origin": path.previous_a, "previous_endpoint": path.previous_b,
	}
	if is_instance_valid(target):
		snapshot["target"] = str(target.get_path())
		snapshot["target_position"] = target.global_position
		snapshot["target_rotation"] = target.global_rotation
		snapshot["target_local_point"] = target_local_point
		if target is RigidBody2D:
			snapshot["target_linear_velocity"] = target.linear_velocity
			snapshot["target_angular_velocity"] = target.angular_velocity
			snapshot["target_mass"] = target.mass
	return snapshot

func step(delta: float, length_input := 0.0) -> void:
	# Capture before force reset so history retains the preceding applied force.
	if settings.gum_diagnostics and state == State.ATTACHED:
		var snapshot := _diagnostic_snapshot()
		snapshot["delta"] = delta
		snapshot["length_input"] = length_input
		diagnostic_history.append(snapshot)
		if diagnostic_history.size() > 8:
			diagnostic_history.pop_front()
	diagnostic_obstruction.clear()
	player_force = Vector2.ZERO
	target_force = Vector2.ZERO
	tension = 0.0
	terrain_forces.clear()
	validate_connection()
	if state == State.OUTBOUND:
		_step_outbound(delta)
		return
	if reeling_food():
		_play_contraction_sound()
		_step_food_reel(delta)
		return
	if state == State.RETURNING:
		_step_return(delta)
		return
	if not connected():
		return
	var contact_tolerance := RIGID_CONTACT_TOLERANCE if target is RigidBody2D else 0.0
	if not path.update(origin(), endpoint(), get_tree().root, settings, true, contact_tolerance):
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
		_play_contraction_sound()
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

func _aim_hit_tile(hit: Dictionary) -> PackedVector2Array:
	if hit.is_empty():
		return PackedVector2Array()
	var body = hit.collider
	var layer: TileMapLayer
	var cell: Vector2i
	if body is TileMapLayer and body.has_body_rid(hit.rid):
		layer = body
		cell = layer.get_coords_for_body_rid(hit.rid)
	elif body is StaticBody2D and body.name == "Terrain":
		layer = body.get_parent().get_node_or_null("TerrainTiles") as TileMapLayer
		if layer == null:
			return PackedVector2Array()
		# Terrain rectangles merge many cells; sample just inside the hit face.
		cell = layer.local_to_map(layer.to_local(hit.position - hit.normal * 0.1))
	else:
		return PackedVector2Array()
	if layer.get_cell_source_id(cell) == -1:
		return PackedVector2Array()
	var center := layer.map_to_local(cell)
	var half := Vector2(layer.tile_set.tile_size) * 0.5
	var polygon := PackedVector2Array()
	for corner in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)]:
		polygon.append(to_local(layer.to_global(center + corner)))
	return polygon

func update_aim(point: Vector2) -> void:
	var hit := cast_to(point)
	aim_valid = attachable(hit)
	var polygon := _aim_hit_tile(hit) if state == State.READY else PackedVector2Array()
	if polygon != aim_tile_polygon:
		aim_blink_time = 0.0
	else:
		aim_blink_time += get_physics_process_delta_time()
	aim_tile_polygon = polygon
	if aim_valid:
		aim_point = _attachment_point(hit)
	elif not hit.is_empty():
		aim_point = hit.position
	else:
		aim_point = origin() + (point - origin()).limit_length(settings.attachment_range)
	queue_redraw()

func _draw() -> void:
	if is_instance_valid(glow_canvas):
		glow_canvas.queue_redraw()
	if not is_instance_valid(player):
		return
	if state == State.READY:
		if not aim_tile_polygon.is_empty():
			var pulse := 0.5 + 0.5 * cos(aim_blink_time * TAU * AIM_TILE_BLINK_HZ)
			var tile_color := settings.aim_valid_color if aim_valid else settings.aim_invalid_color
			var highlight := Color(tile_color, lerpf(0.04, 0.4, pulse))
			draw_colored_polygon(aim_tile_polygon, highlight)
			var outline := aim_tile_polygon.duplicate()
			outline.append(outline[0])
			draw_polyline(outline, Color(highlight, lerpf(0.15, 0.9, pulse)), 2.0)
		var start := to_local(player.gum_visual_origin())
		var aim := to_local(aim_point)
		var aim_color := settings.aim_valid_color if aim_valid else settings.aim_invalid_color
		if not aim_valid:
			aim_color.a *= settings.aim_guide_opacity
		draw_dashed_line(start, aim, aim_color, settings.aim_line_width, settings.aim_dash_length)
		draw_arc(aim, settings.aim_reticle_radius, 0, TAU, 20, aim_color, settings.aim_reticle_width)
		return
	var ratio := tension / settings.maximum_tension
	var color := _gum_color(ratio)
	var points := _display_points()
	var width := settings.gum_line_width + ratio * settings.gum_tension_width
	_draw_gum_shape(self, points, color, width, 0.0)
	var core := color.lerp(Color(1.0, 1.0, 1.0, color.a), settings.gum_core_brightness)
	_draw_gum_shape(self, points, core, maxf(1.0, width * 0.75), 0.0, 0.4)

func _draw_gum_shape(canvas: Node2D, points: PackedVector2Array, color: Color, width: float, spread: float, marker_scale: float = 1.0) -> void:
	if points.size() > 1:
		canvas.draw_polyline(points, color, width + spread * 2.0, true)
	for pivot in path.pivots:
		canvas.draw_circle(to_local(pivot.position), 3.0 * marker_scale + spread, color, true, -1.0, true)
	canvas.draw_circle(to_local(endpoint()), 5.0 * marker_scale + spread, color, true, -1.0, true)

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
	# Adhesion follows the local point even when target rotation hides it.
	# Only other dynamic bodies obstruct the route; static terrain still wraps.
	var excluded: Array[RID] = [player.get_rid(), target_rid]
	for i in range(path.points.size()-1):
		var a: Vector2 = path.points[i]
		var b: Vector2 = path.points[i+1]
		var query := PhysicsRayQueryParameters2D.create(a, b, 4, excluded)
		query.hit_from_inside = true
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			if settings.gum_diagnostics:
				diagnostic_obstruction = {
					"segment": i, "from": a, "to": b,
					"collider": str(hit.collider.get_path()), "is_target": hit.collider == target,
					"position": hit.position, "normal": hit.normal, "shape": hit.shape,
				}
			return true
	return false

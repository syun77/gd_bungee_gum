extends CharacterBody2D
## Feet-origin controller. Game calls simulate() once after gum forces each physics tick.
signal landed(point: Vector2, normal: Vector2, impact_speed: float, surface: Node2D)

const GUM_HANDS := {
	&"gum_fire": [Vector2(180, 143), Vector2(176, 142), Vector2(185, 140), Vector2(196, 135), Vector2(207, 122), Vector2(216, 123), Vector2(214, 123), Vector2(211, 123)],
	&"gum_pull": [Vector2(220, 109), Vector2(216, 109), Vector2(217, 109), Vector2(218, 110), Vector2(220, 106), Vector2(217, 106), Vector2(217, 104), Vector2(219, 102)],
	&"gum_hang": [Vector2(171, 40), Vector2(171, 40), Vector2(171, 40), Vector2(173, 40), Vector2(171, 40), Vector2(171, 40), Vector2(171, 40), Vector2(172, 40)],
}


const COMPRESSION_CLEARANCE := 0.25
const SUPPORT_FACE_TOLERANCE := 0.5
const LANDING_MINIMUM_AIR_TIME := 0.05
const LANDING_MINIMUM_AIR_DISTANCE := 2.0
const Settings = preload("res://scripts/game_settings.gd")
@export var settings: Settings
var visual_deformation := Vector2.ONE
var visual_deformation_time := 0.0
var visual_deformation_duration := 0.0
var sprite_rest_scale := Vector2.ONE
var sprite_rest_position := Vector2.ZERO
var external_velocity := Vector2.ZERO
var control_velocity := Vector2.ZERO
var kick_available := true
var coyote_remaining := 0.0
var coyote_gravity_velocity := Vector2.ZERO
var landing_time := 0.0
var landing_floor_seen := false
var landing_air_time := 0.0
var landing_air_distance := 0.0
var gum: Node2D
var contact_diagnostic_next_tick := 0
var compression_diagnostic_next_tick := 0
var rigid_contact_probe := CapsuleShape2D.new()
var pinning_diagnostic_active := false
var pinning_diagnostic_next_tick := 0
var pinning_diagnostic_input: Dictionary = {}
var pinning_diagnostic_gum_state := ""
var pinning_diagnostic_history: Array[Dictionary] = []
var landing_diagnostic_active := false
var landing_diagnostic_next_tick := 0
var landing_diagnostic_transitions := 0
var landing_diagnostic_details := 0
var landing_diagnostic_next_impact_tick := 0
var afterimages = preload("res://scripts/player_afterimages.gd").new()
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_child(afterimages)
	afterimages.show_behind_parent = true
	sprite_rest_scale = sprite.scale
	sprite_rest_position = sprite.position
	var poses: SpriteFrames = preload("res://assets/characters/teto/gum_animations.tres")
	sprite.sprite_frames = sprite.sprite_frames.duplicate()
	for animation in poses.get_animation_names():
		sprite.sprite_frames.add_animation(animation)
		sprite.sprite_frames.set_animation_speed(animation, poses.get_animation_speed(animation))
		sprite.sprite_frames.set_animation_loop(animation, poses.get_animation_loop(animation))
		for index in poses.get_frame_count(animation):
			sprite.sprite_frames.add_frame(animation, poses.get_frame_texture(animation, index), poses.get_frame_duration(animation, index))

func fire_gum() -> void:
	sprite.stop()
	sprite.play("gum_fire")

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

func simulate(delta: float, jump_requested := false, attached_jump := false) -> void:
	# 接触判定は直前の move_and_slide() の結果。今回の移動後に更新される。
	var grounded := is_on_floor()
	var touching := grounded or is_on_wall() or is_on_ceiling()
	if grounded:
		coyote_remaining = settings.coyote_time
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
	var direction := Input.get_axis("move_left", "move_right")
	var acceleration := settings.ground_acceleration if grounded else settings.air_acceleration
	# 入力速度は設定の加速度で目標速度へ近づけ、無入力ではゼロへ減速する。
	var removed_control_y := control_velocity.y
	control_velocity = Vector2(move_toward(control_velocity.x, direction * settings.run_speed, acceleration * delta), 0.0)
	var gravity_velocity := Vector2(0.0, settings.gravity * delta)
	external_velocity += gravity_velocity
	if coyote_remaining > 0.0:
		coyote_gravity_velocity += gravity_velocity
	var coyote_kick := not touching and coyote_remaining > 0.0
	attached_jump = attached_jump and jump_requested
	var can_kick := attached_jump or (kick_available and (touching or coyote_kick))
	if jump_requested:
		var result := "REJECTED_NO_CONTACT" if not touching else "REJECTED_NOT_REARMED"
		if can_kick:
			result = "ACCEPTED_GUM" if attached_jump else ("ACCEPTED_COYOTE" if coyote_kick else "ACCEPTED")
		_log_jump_state(result)
	if jump_requested and can_kick:
		var kick_direction := Vector2.UP
		if touching and not grounded and not attached_jump:
			kick_direction = get_wall_normal() if is_on_wall() else Vector2.DOWN
		var external_before := external_velocity
		var compensation := Vector2.ZERO
		if attached_jump:
			compensation = Vector2.UP * maxf(external_velocity.y, 0.0)
		elif coyote_kick:
			var falling_speed := maxf(external_velocity.y, 0.0)
			var gravity_fall := maxf(coyote_gravity_velocity.y, 0.0)
			compensation = Vector2.UP * minf(falling_speed, gravity_fall)
		external_velocity += compensation
		var impulse := kick_direction * settings.kick_speed
		external_velocity += impulse
		if impulse.y < 0.0 and (control_velocity + external_velocity).y < 0.0:
			_start_visual_deformation(settings.jump_stretch, settings.jump_stretch_duration)
		if settings.jump_diagnostics:
			print("[JumpDiagnostic] KICK_APPLIED tick=%d feet=%s source=%s normal=%s angle_from_up_deg=%.3f impulse=%s compensation=%s external_before=%s external_after=%s control=%s launch=%s delta=%.6f" % [
				Engine.get_physics_frames(), global_position,
				"gum" if attached_jump else ("coyote" if coyote_kick else ("floor" if grounded else ("wall" if is_on_wall() else "ceiling"))),
				kick_direction, rad_to_deg(Vector2.UP.angle_to(kick_direction)), impulse, compensation,
				external_before, external_velocity, control_velocity, control_velocity + external_velocity, delta])
		kick_available = false
		coyote_remaining = 0.0
		coyote_gravity_velocity = Vector2.ZERO
	# 外部速度は空中で保持し、接地後に床面方向の摩擦で減速する。
	velocity = control_velocity + external_velocity
	var landing_incoming := velocity
	var pending_impulses := _solve_rigid_contacts(delta, velocity)
	velocity = control_velocity + external_velocity
	var incoming_velocity := velocity
	var before_position := global_position
	var before_control := control_velocity
	var before_external := external_velocity
	_move_with_face_support(delta, grounded)
	var slide_velocity := velocity
	var collision_contacts: Array[Dictionary] = pending_impulses.duplicate()
	collision_contacts.append_array(_slide_contacts())
	var compression_recovered := _recover_rigid_compression(delta, incoming_velocity)
	if compression_recovered:
		collision_contacts.append_array(_slide_contacts())
		if is_on_floor():
			collision_contacts.append({"normal": get_floor_normal()})
	# Resolve support against the contacted face, rather than the rounded capsule corner.
	var support_normal := get_floor_normal() if is_on_floor() else up_direction
	for contact in collision_contacts:
		var normal := _support_face_normal(contact)
		if is_on_floor() and _is_support_normal(normal):
			support_normal = normal
		var external_before_contact := external_velocity
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
		var body = contact.get("body")
		if body is RigidBody2D and not body.freeze and _is_support_normal(normal):
			var impulse := (external_before_contact - external_velocity) * settings.player_mass
			if not impulse.is_zero_approx():
				pending_impulses.append({"body": body, "point": contact.point, "normal": normal,
					"impulse": impulse, "kind": "support"})
	_update_landing_event(delta, grounded, before_position, landing_incoming, compression_recovered)
	_apply_ground_friction(delta, support_normal)
	_apply_rigid_impulses(pending_impulses)
	velocity = control_velocity + external_velocity
	if not grounded and is_on_floor():
		landing_time = 0.12
	landing_time = maxf(landing_time - delta, 0.0)
	_update_animation(direction)
	_update_visual_deformation(delta)
	afterimages.step(delta, sprite, global_position.distance_to(before_position) / maxf(delta, 0.000001), settings)
	if jump_requested:
		_log_jump_state("AFTER_MOVE", incoming_velocity)
	_log_landing_state(grounded, incoming_velocity, removed_control_y)
	_log_pinning_state(delta, direction, jump_requested, before_position, before_control, before_external, incoming_velocity, slide_velocity)

func _update_landing_event(delta: float, was_grounded: bool, before_position: Vector2,
		incoming: Vector2, compression_recovered: bool) -> void:
	if not is_on_floor():
		if landing_floor_seen:
			landing_air_time += delta
			landing_air_distance += global_position.distance_to(before_position)
		return
	# Spawn settling and brief contact flicker are not landings.
	if (not was_grounded and landing_floor_seen and landing_air_time >= LANDING_MINIMUM_AIR_TIME
			and landing_air_distance >= LANDING_MINIMUM_AIR_DISTANCE and not compression_recovered):
		var strongest := 0.0
		var support: Dictionary = {}
		for contact in _slide_contacts():
			var normal := _support_face_normal(contact)
			if not _is_support_normal(normal):
				continue
			var surface_velocity := Vector2.ZERO
			var body = contact.body
			if body is RigidBody2D:
				var state := PhysicsServer2D.body_get_direct_state(body.get_rid())
				if state != null:
					var radius: Vector2 = contact.point - (state.transform.origin + state.center_of_mass)
					surface_velocity = state.linear_velocity + Vector2(-radius.y, radius.x) * state.angular_velocity
			elif body is StaticBody2D:
				surface_velocity = body.constant_linear_velocity
			var speed := maxf(0.0, -(incoming - surface_velocity).dot(normal))
			if speed > strongest:
				strongest = speed
				support = contact.merged({"face_normal": normal})
		if not support.is_empty():
			_start_visual_deformation(settings.landing_squash, settings.landing_squash_duration)
			landed.emit(support.point, support.face_normal, strongest, support.body as Node2D)
	landing_floor_seen = true
	landing_air_time = 0.0
	landing_air_distance = 0.0

func _start_visual_deformation(deformation: Vector2, duration: float) -> void:
	visual_deformation = deformation
	visual_deformation_duration = duration
	visual_deformation_time = duration

func _update_visual_deformation(delta: float) -> void:
	# Scale only the artwork around the feet; body, capsule and physics origins stay fixed.
	var weight := 0.0
	if visual_deformation_time > 0.0:
		weight = pow(visual_deformation_time / visual_deformation_duration, 2.0)
	var deformation := Vector2.ONE.lerp(visual_deformation, weight)
	sprite.scale = sprite_rest_scale * deformation
	sprite.position = sprite_rest_position * deformation
	visual_deformation_time = maxf(visual_deformation_time - delta, 0.0)

func _log_jump_state(event: String, incoming := Vector2.ZERO) -> void:
	if not settings.jump_diagnostics:
		return
	var contacts: Array[String] = []
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		contacts.append("{collider=%s point=%s normal=%s depth=%.4f}" % [
			str(collider.get_path()) if collider is Node else str(collider),
			collision.get_position(), collision.get_normal(), collision.get_depth()])
	var attached: bool = is_instance_valid(gum) and gum.connected()
	print("[JumpDiagnostic] %s tick=%d feet=%s floor=%s wall=%s ceiling=%s available=%s z_held=%s x_held=%s control=%s external=%s incoming=%s contacts=%s gum=%s coyote=%.3f floor_normal=%s wall_normal=%s real_velocity=%s position_delta=%s" % [
		event, Engine.get_physics_frames(), global_position, is_on_floor(), is_on_wall(), is_on_ceiling(),
		kick_available, Input.is_action_pressed("jump"), Input.is_action_pressed("gum_action"),
		control_velocity, external_velocity, incoming, contacts, attached, coyote_remaining,
		get_floor_normal(), get_wall_normal(), get_real_velocity(), get_position_delta()])

func _apply_ground_friction(delta: float, normal: Vector2) -> void:
	if not is_on_floor():
		return
	var tangent := normal.orthogonal()
	var speed := external_velocity.dot(tangent)
	external_velocity += tangent * (move_toward(speed, 0.0, settings.ground_friction * delta) - speed)

func _update_animation(direction: float) -> void:
	# 絵の左右向きは実速度ではなく入力に即追従する。方向転換の減速中や
	# 外部速度で流されているときは、向きと実際の進行方向が逆になる。
	if direction != 0.0:
		sprite.flip_h = direction < 0.0
	if is_instance_valid(gum) and (gum.connected() or gum.state == gum.State.OUTBOUND):
		var aim: Vector2 = gum.support_point() - gum.origin()
		sprite.flip_h = aim.x < 0.0
		if gum.state == gum.State.OUTBOUND:
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
		sprite.play("run" if direction != 0.0 or absf(velocity.x) > 12.0 else "idle")

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
	print("[LandingDiagnostic] %s tick=%d feet=%s control=%s external=%s floor=%s->%s transitions=%d animation=%s landing=%.3f gum=%s reason=%s tension=%.1f incoming=%s removed_control_y=%.3f normals=%s" % [
		event, tick, global_position, control_velocity, external_velocity,
		was_grounded, is_on_floor(), landing_diagnostic_transitions,
		sprite.animation, landing_time, attached, gum_status, gum_tension, incoming_velocity, removed_control_y, normals])

func _log_pinning_state(delta: float, direction: float, jump_requested: bool, before_position: Vector2, before_control: Vector2, before_external: Vector2, incoming: Vector2, slide_velocity: Vector2) -> void:
	if not settings.pinning_diagnostics:
		pinning_diagnostic_active = false
		pinning_diagnostic_history.clear()
		return
	var contacts: Array[Dictionary] = []
	var rigid_contact := false
	var deepest_contact := 0.0
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var body := hit.get_collider()
		deepest_contact = maxf(deepest_contact, hit.get_depth())
		rigid_contact = rigid_contact or body is RigidBody2D
		var contact := _pinning_body_state(body)
		contact.merge({"normal": hit.get_normal(), "point": hit.get_position(),
			"depth": hit.get_depth(), "collider_velocity": hit.get_collider_velocity(),
			"travel": hit.get_travel(), "remainder": hit.get_remainder()})
		contacts.append(contact)
	var displacement := global_position - before_position
	var stalled_penetration := deepest_contact >= 1.0 and incoming.length() >= 10.0 and displacement.length() < 0.1
	var watched_contact := rigid_contact or stalled_penetration
	var gum_state := "NO GUM"
	var gum_snapshot: Dictionary = {}
	if is_instance_valid(gum):
		gum_state = "%s/%s" % [gum.state, gum.mode]
		gum_snapshot = {"state": gum.State.keys()[gum.state], "mode": gum.Mode.keys()[gum.mode],
			"connected": gum.connected(), "reason": gum.release_reason,
			"tension": gum.tension, "player_force": gum.player_force, "target_force": gum.target_force,
			"length": gum.path.length, "rest_length": gum.rest_length}
		if gum.connected():
			gum_snapshot["target"] = str(gum.target.get_path())
			gum_snapshot["endpoint"] = gum.endpoint()
	var input_state := {"move_axis": direction, "z_held": Input.is_action_pressed("jump"),
		"x_held": Input.is_action_pressed("gum_action"), "up": Input.is_action_pressed("aim_up"),
		"down": Input.is_action_pressed("aim_down")}
	var tick := Engine.get_physics_frames()
	var snapshot := {"tick": tick, "delta": delta, "feet_before": before_position, "feet": global_position,
		"displacement": displacement, "real_velocity": get_real_velocity(),
		"rigid_contact": rigid_contact, "stalled_penetration": stalled_penetration,
		"deepest_contact": deepest_contact, "slide_count": get_slide_collision_count(),
		"jump_requested": jump_requested,
		"control_before": before_control, "external_before": before_external, "incoming": incoming,
		"slide_velocity": slide_velocity, "control_after": control_velocity, "external_after": external_velocity,
		"floor": is_on_floor(), "wall": is_on_wall(), "ceiling": is_on_ceiling(),
		"kick_available": kick_available, "coyote": coyote_remaining,
		"platform_velocity": get_platform_velocity(), "platform_floor_layers": platform_floor_layers,
		"safe_margin": safe_margin, "max_slides": max_slides, "contacts": contacts, "gum": gum_snapshot}
	snapshot.merge(input_state)
	var event := ""
	if watched_contact and not pinning_diagnostic_active:
		event = "CONTACT_STARTED"
	elif pinning_diagnostic_active:
		if not watched_contact:
			event = "CONTACT_ENDED"
		elif jump_requested or input_state != pinning_diagnostic_input or gum_state != pinning_diagnostic_gum_state:
			event = "ACTION_CHANGED"
		elif tick >= pinning_diagnostic_next_tick:
			event = "PERSISTING"
	if not event.is_empty():
		print("[PinningDiagnostic] ", event, " snapshot=", snapshot, " nearby=", _pinning_nearby_bodies())
		if event == "CONTACT_STARTED":
			for previous in pinning_diagnostic_history:
				print("[PinningDiagnostic] HISTORY ", previous)
		pinning_diagnostic_next_tick = tick + 30
	pinning_diagnostic_active = watched_contact
	pinning_diagnostic_input = input_state
	pinning_diagnostic_gum_state = gum_state
	pinning_diagnostic_history.append(snapshot)
	if pinning_diagnostic_history.size() > 8:
		pinning_diagnostic_history.pop_front()

func _pinning_body_state(body: Object) -> Dictionary:
	var result := {"collider": str(body.get_path()) if body is Node else str(body)}
	if body is Node2D:
		result.merge({"position": body.global_position, "rotation": body.global_rotation})
	if body is RigidBody2D:
		result.merge({"mass": body.mass, "linear_velocity": body.linear_velocity,
			"angular_velocity": body.angular_velocity, "sleeping": body.sleeping, "freeze": body.freeze})
	return result

func _pinning_nearby_bodies() -> Array[Dictionary]:
	# Recovery contacts may be absent from slide results; this is proximity, not contact proof.
	var collider: CollisionShape2D = $CollisionShape2D
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collider.shape
	query.transform = collider.global_transform
	query.margin = 2.0
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	var result: Array[Dictionary] = []
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var body := _pinning_body_state(hit.collider)
		body["shape"] = hit.shape
		result.append(body)
	return result

func _nearby_movable_rigids() -> Array[RigidBody2D]:
	var collider: CollisionShape2D = $CollisionShape2D
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collider.shape
	query.transform = collider.global_transform
	query.margin = 2.0
	query.collision_mask = collision_mask & 4
	query.exclude = [get_rid()]
	var bodies: Array[RigidBody2D] = []
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 16):
		if hit.collider is RigidBody2D and not hit.collider.freeze and hit.collider not in bodies:
			bodies.append(hit.collider)
	return bodies

func _rigid_contacts(bodies: Array[RigidBody2D]) -> Array[Dictionary]:
	var contacts: Array[Dictionary] = []
	if bodies.is_empty():
		return contacts
	var collider: CollisionShape2D = $CollisionShape2D
	var capsule: CapsuleShape2D = collider.shape
	rigid_contact_probe.radius = capsule.radius + settings.contact_clearance
	rigid_contact_probe.height = capsule.height + settings.contact_clearance * 2.0
	# Direct shape pairs avoid changing live body masks/contact caches.
	for body in bodies:
		var deepest := 0.0
		var normal := Vector2.ZERO
		var point := Vector2.ZERO
		var shape_index := -1
		for owner in body.get_shape_owners():
			if body.is_shape_owner_disabled(owner):
				continue
			var transform := body.global_transform * body.shape_owner_get_transform(owner)
			for index in body.shape_owner_get_shape_count(owner):
				var shape: Shape2D = body.shape_owner_get_shape(owner, index)
				var pairs := rigid_contact_probe.collide_and_get_contacts(collider.global_transform, shape, transform)
				for i in range(0, pairs.size(), 2):
					var separation: Vector2 = pairs[i + 1] - pairs[i]
					if separation.length() > deepest:
						deepest = separation.length()
						normal = separation.normalized()
						point = pairs[i + 1]
						shape_index = body.shape_owner_get_shape_index(owner, index)
		if deepest > 0.001:
			contacts.append({"body": body, "depth": deepest, "normal": normal, "point": point, "shape": shape_index})
	return contacts

func _is_support_normal(normal: Vector2) -> bool:
	return normal.dot(up_direction) >= cos(floor_max_angle)

func _slide_contacts() -> Array[Dictionary]:
	var contacts: Array[Dictionary] = []
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		contacts.append({"normal": collision.get_normal(), "body": collision.get_collider(),
			"point": collision.get_position(), "shape": collision.get_collider_shape_index(),
			"rid": collision.get_collider_rid()})
	return contacts

func _move_with_face_support(delta: float, grounded: bool) -> void:
	var supported_angle := _predicted_support_angle(delta)
	if grounded:
		# Do not drive gravity into a supported rounded corner each tick.
		# External momentum is still resolved after movement for reciprocal reactions.
		for contact in _slide_contacts():
			var face := _support_face_normal(contact)
			if _is_support_normal(face) and velocity.dot(face) < 0.0:
				velocity = velocity.slide(face)
	var configured_angle := floor_max_angle
	floor_max_angle = supported_angle
	move_and_slide()
	floor_max_angle = configured_angle

func _predicted_support_angle(delta: float) -> float:
	# Only a verified walkable face may turn a steep capsule corner into floor support.
	# Keeping the engine's floor classification lets stop-on-slope and platform carry work.
	if velocity.dot(up_direction) > 0.0:
		return floor_max_angle
	var hit := KinematicCollision2D.new()
	if not test_move(global_transform, velocity * delta, hit, safe_margin, true):
		return floor_max_angle
	var contact := {"normal": hit.get_normal(), "body": hit.get_collider(),
		"shape": hit.get_collider_shape_index(), "point": hit.get_position(), "rid": hit.get_collider_rid()}
	var normal: Vector2 = contact.normal
	if not _is_support_normal(_support_face_normal(contact)):
		return floor_max_angle
	var angle := acos(clampf(normal.dot(up_direction), -1.0, 1.0))
	return maxf(floor_max_angle, minf(angle + 0.001, PI * 0.5 - 0.001))

func _support_face_normal(contact: Dictionary) -> Vector2:
	var normal: Vector2 = contact.normal
	var body = contact.get("body")
	if normal.dot(up_direction) <= 0.0 or not contact.has("shape"):
		return normal
	if body is TileMapLayer:
		return _tile_support_face_normal(contact)
	if not body is CollisionObject2D:
		return normal
	var shape_index: int = contact.shape
	var owner: int = body.shape_find_owner(shape_index)
	if body.is_shape_owner_disabled(owner):
		return normal
	var transform: Transform2D = body.global_transform * body.shape_owner_get_transform(owner)
	for index in body.shape_owner_get_shape_count(owner):
		if body.shape_owner_get_shape_index(owner, index) != shape_index:
			continue
		var shape: Shape2D = body.shape_owner_get_shape(owner, index)
		if not shape is RectangleShape2D:
			return normal
		var local_point: Vector2 = transform.affine_inverse() * contact.point
		var half: Vector2 = shape.size * 0.5
		# Resolve all four edges: a rotated box's supporting face need not be local top.
		var edges := [
			[Vector2(-half.x, -half.y), Vector2(half.x, -half.y)],
			[Vector2(half.x, -half.y), Vector2(half.x, half.y)],
			[Vector2(half.x, half.y), Vector2(-half.x, half.y)],
			[Vector2(-half.x, half.y), Vector2(-half.x, -half.y)],
		]
		for edge in edges:
			var closest := Geometry2D.get_closest_point_to_segment(local_point, edge[0], edge[1])
			if (transform * closest).distance_to(contact.point) > SUPPORT_FACE_TOLERANCE:
				continue
			var tangent: Vector2 = transform.basis_xform(edge[1] - edge[0])
			var face_normal := Vector2(tangent.y, -tangent.x).normalized() * signf(transform.determinant())
			if _is_support_normal(face_normal):
				return face_normal
	return normal

func _tile_support_face_normal(contact: Dictionary) -> Vector2:
	# TileMapLayer owns server bodies rather than CollisionObject2D shape owners.
	var rid: RID = contact.get("rid", RID())
	if not rid.is_valid() or not contact.body.has_body_rid(rid):
		return contact.normal
	var shape: RID = PhysicsServer2D.body_get_shape(rid, contact.shape)
	if PhysicsServer2D.shape_get_type(shape) != PhysicsServer2D.SHAPE_CONVEX_POLYGON:
		return contact.normal
	var points: PackedVector2Array = PhysicsServer2D.shape_get_data(shape)
	var transform: Transform2D = PhysicsServer2D.body_get_state(rid, PhysicsServer2D.BODY_STATE_TRANSFORM)
	transform = transform * PhysicsServer2D.body_get_shape_transform(rid, contact.shape)
	var center := Vector2.ZERO
	for point in points:
		center += transform * point
	center /= points.size()
	for index in points.size():
		var a := transform * points[index]
		var b := transform * points[(index + 1) % points.size()]
		if Geometry2D.get_closest_point_to_segment(contact.point, a, b).distance_to(contact.point) > SUPPORT_FACE_TOLERANCE:
			continue
		var tangent := b - a
		var normal := Vector2(tangent.y, -tangent.x).normalized()
		if normal.dot((a + b) * 0.5 - center) < 0.0:
			normal = -normal
		if _is_support_normal(normal):
			return normal
	return contact.normal

func _solve_rigid_contacts(delta: float, incoming: Vector2) -> Array[Dictionary]:
	var contacts: Array[Dictionary] = []
	for contact in _rigid_contacts(_nearby_movable_rigids()):
		# Supporting surfaces are resolved by move_and_slide, without a separation target.
		if not _is_support_normal(_support_face_normal(contact)):
			contacts.append(contact)
	var original_external := external_velocity
	for contact in contacts:
		var body: RigidBody2D = contact.body
		var normal: Vector2 = contact.normal
		var physics := PhysicsServer2D.body_get_direct_state(body.get_rid())
		var radius: Vector2 = contact.point - (physics.transform.origin + physics.center_of_mass)
		var point_velocity := physics.linear_velocity + Vector2(-radius.y, radius.x) * physics.angular_velocity
		var closing_speed := (point_velocity - incoming).dot(normal)
		var restitution: float = settings.contact_restitution if closing_speed > 30.0 else 0.0
		var bias := minf(settings.contact_separation_speed, maxf(contact.depth - 0.05, 0.0) * settings.contact_penetration_response / delta)
		contact.merge({"radius": radius, "inverse_mass": 1.0 / settings.player_mass + physics.inverse_mass + radius.cross(normal) ** 2 * physics.inverse_inertia,
			"body_inverse_mass": physics.inverse_mass, "body_inverse_inertia": physics.inverse_inertia,
			"linear_velocity": physics.linear_velocity, "angular_velocity": physics.angular_velocity,
			"target_speed": bias + restitution * maxf(closing_speed, 0.0), "accumulated": 0.0,
			"closing_speed": closing_speed})
	# Virtual body velocities keep same-tick reactions out of automatic platform carry.
	for iteration in 8:
		for contact in contacts:
			var radius: Vector2 = contact.radius
			var point_velocity: Vector2 = contact.linear_velocity + Vector2(-radius.y, radius.x) * contact.angular_velocity
			var player_velocity := incoming + external_velocity - original_external
			var closing_speed: float = (point_velocity - player_velocity).dot(contact.normal)
			var accumulated := maxf(contact.accumulated + (closing_speed + contact.target_speed) / contact.inverse_mass, 0.0)
			var impulse: Vector2 = -contact.normal * (accumulated - contact.accumulated)
			contact.accumulated = accumulated
			contact.linear_velocity += impulse * contact.body_inverse_mass
			contact.angular_velocity += radius.cross(impulse) * contact.body_inverse_inertia
			external_velocity -= impulse / settings.player_mass
	for contact in contacts:
		contact["impulse"] = -contact.normal * contact.accumulated
		contact["kind"] = "repel"
	return contacts

func _apply_rigid_impulses(contacts: Array[Dictionary]) -> void:
	var diagnostics: Array[Dictionary] = []
	for contact in contacts:
		var body: RigidBody2D = contact.body
		var before: Vector2 = PhysicsServer2D.body_get_state(body.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY)
		if not contact.impulse.is_zero_approx():
			body.sleeping = false
			body.apply_impulse(contact.impulse, contact.point - body.global_position)
		if settings.pinning_diagnostics:
			diagnostics.append({"body": str(body.get_path()), "kind": contact.kind, "point": contact.point,
				"normal": contact.normal, "depth": contact.get("depth", 0.0),
				"closing_speed": contact.get("closing_speed", 0.0), "target_speed": contact.get("target_speed", 0.0),
				"impulse": contact.impulse, "body_velocity_before": before,
				"body_velocity_after": PhysicsServer2D.body_get_state(body.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY)})
	var tick := Engine.get_physics_frames()
	if not diagnostics.is_empty() and tick >= contact_diagnostic_next_tick:
		print("[PinningDiagnostic] CONTACT_IMPULSE tick=", tick, " contacts=", diagnostics)
		contact_diagnostic_next_tick = tick + 30

func _recover_rigid_compression(delta: float, incoming: Vector2) -> bool:
	var bodies := _nearby_movable_rigids()
	if bodies.is_empty():
		return false
	var collider: CollisionShape2D = $CollisionShape2D
	var saved_mask := collision_mask
	var parameters := PhysicsTestMotionParameters2D.new()
	parameters.margin = safe_margin
	var excluded: Array[RID] = []
	for body in bodies:
		excluded.append(body.get_rid())
	parameters.exclude_bodies = excluded
	parameters.recovery_as_collision = true
	var result := PhysicsTestMotionResult2D.new()
	parameters.from = global_transform
	PhysicsServer2D.body_test_motion(get_rid(), parameters, result)
	if result.get_travel().length() < 0.01:
		return false
	var start := global_position
	parameters.margin += COMPRESSION_CLEARANCE
	for iteration in 8:
		parameters.from = global_transform
		PhysicsServer2D.body_test_motion(get_rid(), parameters, result)
		var recovery := result.get_travel()
		if recovery.length_squared() < 0.000001:
			break
		global_position += recovery
	var correction := global_position - start
	if correction.length_squared() > 0.000001:
		for body in bodies:
			var direction := correction.normalized()
			if (body.global_position - collider.global_position).dot(direction) <= 0.0:
				continue
			var approaching := maxf(-body.linear_velocity.dot(direction), 0.0)
			var impulse := direction * body.mass * (correction.length() / delta + approaching)
			body.sleeping = false
			body.apply_central_impulse(impulse)
			external_velocity -= impulse / settings.player_mass
		collision_mask = saved_mask & ~4
		velocity = Vector2(0.0, 0.01 if incoming.y >= 0.0 else -0.01)
		move_and_slide()
		var tick := Engine.get_physics_frames()
		if settings.pinning_diagnostics and tick >= compression_diagnostic_next_tick:
			print("[PinningDiagnostic] COMPRESSION_RECOVERED tick=", tick, " correction=", correction)
			compression_diagnostic_next_tick = tick + 30
	collision_mask = saved_mask
	return correction.length_squared() > 0.000001

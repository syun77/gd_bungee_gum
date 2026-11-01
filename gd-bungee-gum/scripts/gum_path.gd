extends RefCounted
const Geometry = preload("res://scripts/gum_terrain_geometry.gd")
var geometry = Geometry.new()
var pivots: Array[Dictionary] = []
var points := PackedVector2Array()
var previous_a := Vector2.ZERO
var previous_b := Vector2.ZERO
var initialized := false
var length := 0.0
var failure := ""
var modifications := 0

func reset(a: Vector2, b: Vector2) -> void:
	pivots.clear()
	points = PackedVector2Array([a, b])
	previous_a = a
	previous_b = b
	initialized = true
	length = a.distance_to(b)
	failure = ""

func _points(a: Vector2, b: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array([a])
	for pivot in pivots:
		result.append(pivot.position)
	result.append(b)
	return result

func update(a: Vector2, b: Vector2, root: Node, settings: Resource, advance_release := true) -> bool:
	failure = ""
	modifications = 0
	if not initialized:
		reset(a,b)
	var changed: bool = geometry.refresh(root, settings.wrap_clearance)
	if geometry.unsupported:
		failure = "UNSUPPORTED OBSTACLE"
		return false
	if changed:
		for i in range(pivots.size()-1, -1, -1):
			var exists := false
			for corner in geometry.corners:
				if corner.position.is_equal_approx(pivots[i].position):
					exists = true
			if not exists:
				pivots.remove_at(i)
	# Interpolate endpoint motion at sub-pixel corner clearance resolution. Existing
	# pivots constrain each local repair, retaining the side selected on first contact.
	var samples := maxi(1, ceili(maxf(a.distance_to(previous_a), b.distance_to(previous_b)) / maxf(settings.wrap_clearance, 0.25)))
	if samples > 4096:
		failure = "PATH LIMIT"
		return false
	for sample in range(1, samples+1):
		var t := float(sample) / samples
		if not _repair(previous_a.lerp(a,t), previous_b.lerp(b,t), settings):
			return false
	points = _points(a,b)
	# Unwrap only when the shortcut clears an expanded collision silhouette.
	for i in range(pivots.size()-1, -1, -1):
		var clear: bool = geometry.visible(points[i], points[i+2], settings.wrap_release_margin)
		pivots[i].clear_ticks = pivots[i].clear_ticks + (1 if advance_release else 0) if clear else 0
		if pivots[i].clear_ticks >= settings.wrap_release_ticks:
			pivots.remove_at(i)
			points = _points(a,b)
	length = 0.0
	for i in range(points.size()-1):
		length += points[i].distance_to(points[i+1])
	previous_a = a
	previous_b = b
	return true

func _repair(a: Vector2, b: Vector2, settings: Resource) -> bool:
	var current := _points(a,b)
	var i := 0
	while i < current.size()-1:
		if geometry.visible(current[i],current[i+1]):
			i += 1
			continue
		modifications += 1
		if modifications > settings.wrap_max_repairs:
			failure = "PATH LIMIT"
			return false
		var route := _route(current[i],current[i+1], settings.maximum_length)
		if route.is_empty():
			failure = "PATH INVALID"
			return false
		if pivots.size() + route.size() > settings.wrap_max_pivots:
			failure = "PATH LIMIT"
			return false
		for j in route.size():
			pivots.insert(i+j, {"position": route[j], "clear_ticks": 0})
		current = _points(a,b)
		i += route.size() + 1
	return true

func _route(a: Vector2, b: Vector2, maximum_length: float) -> PackedVector2Array:
	var nodes := PackedVector2Array([a,b])
	for corner in geometry.corners:
		if a.distance_to(corner.position) + b.distance_to(corner.position) <= maximum_length * 2:
			nodes.append(corner.position)
	var distances: Array[float] = []
	var parents: Array[int] = []
	var visited: Array[bool] = []
	for node in nodes:
		distances.append(INF)
		parents.append(-1)
		visited.append(false)
	distances[0] = 0.0
	for iteration in nodes.size():
		var best := -1
		for i in nodes.size():
			if not visited[i] and (best < 0 or distances[i] < distances[best]):
				best = i
		if best < 0 or is_inf(distances[best]):
			break
		if best == 1:
			var result := PackedVector2Array()
			var index := parents[1]
			while index > 1:
				result.insert(0,nodes[index])
				index = parents[index]
			return result
		visited[best] = true
		for i in nodes.size():
			if visited[i]:
				continue
			var distance := distances[best] + nodes[best].distance_to(nodes[i])
			if distance < distances[i] and geometry.visible(nodes[best],nodes[i]):
				distances[i] = distance
				parents[i] = best
	return PackedVector2Array()

func start_direction() -> Vector2:
	return (points[1]-points[0]).normalized()

func end_direction() -> Vector2:
	return (points[-1]-points[-2]).normalized()

func speed(a_velocity: Vector2, b_velocity: Vector2) -> float:
	return -a_velocity.dot(start_direction()) + b_velocity.dot(end_direction())

func reactions(tension: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in range(1,points.size()-1):
		result.append(tension*((points[i+1]-points[i]).normalized()-(points[i]-points[i-1]).normalized()))
	return result

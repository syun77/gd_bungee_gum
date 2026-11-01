extends RefCounted
## Collision-derived static polygon union boundary and visibility queries.
var polygons: Array[PackedVector2Array] = []
var corners: Array[Dictionary] = []
var signature := ""
var unsupported := false

func refresh(root: Node, clearance: float) -> bool:
	var shapes: Array[CollisionShape2D] = []
	_collect(root, shapes)
	var key := str(clearance)
	for node in shapes:
		key += str(node.get_instance_id()) + str(node.global_transform) + str(node.shape) + str(node.shape.get("size") if node.shape is RectangleShape2D else node.shape.get("points"))
	if key == signature:
		return false
	signature = key
	polygons.clear()
	corners.clear()
	unsupported = false
	for node in shapes:
		var points := PackedVector2Array()
		if node.shape is RectangleShape2D:
			var half: Vector2 = node.shape.size / 2.0
			points = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)])
		elif node.shape is ConvexPolygonShape2D:
			points = node.shape.points
		else:
			unsupported = true
			continue
		for i in points.size():
			points[i] = node.global_transform * points[i]
		if Geometry2D.is_polygon_clockwise(points):
			points.reverse()
		polygons.append(points)
	_build_corners(clearance)
	return true

func _collect(node: Node, result: Array[CollisionShape2D]) -> void:
	if node is CollisionShape2D and not node.disabled and node.shape != null and node.get_parent() is StaticBody2D and node.get_parent().collision_layer & 5:
		result.append(node)
	for child in node.get_children():
		_collect(child, result)

func inside(point: Vector2) -> bool:
	for polygon in polygons:
		if _contains(point, polygon):
			return true
	return false

func _build_corners(clearance: float) -> void:
	# Split all collision edges at intersections; remove internal/shared edges.
	var edges: Array[Dictionary] = []
	for polygon in polygons:
		for i in polygon.size():
			var a := polygon[i]
			var b := polygon[(i + 1) % polygon.size()]
			var cuts: Array[Vector2] = [a, b]
			for other in polygons:
				for j in other.size():
					var c := other[j]
					var d := other[(j + 1) % other.size()]
					var hit = Geometry2D.segment_intersects_segment(a, b, c, d)
					if hit != null:
						cuts.append(hit)
					for point in [c, d]:
						if Geometry2D.get_closest_point_to_segment(point, a, b).distance_to(point) < 0.001:
							cuts.append(point)
			cuts.sort_custom(func(x: Vector2, y: Vector2): return a.distance_squared_to(x) < a.distance_squared_to(y))
			var outward := Vector2((b-a).y, -(b-a).x).normalized()
			for j in range(cuts.size() - 1):
				if cuts[j].distance_to(cuts[j+1]) < 0.001:
					continue
				var mid := (cuts[j] + cuts[j+1]) / 2
				if not inside(mid + outward * 0.01):
					edges.append({"a": cuts[j], "b": cuts[j+1], "normal": outward})
	for edge in edges:
		for next in edges:
			if edge.b.distance_to(next.a) > 0.001:
				continue
			if (edge.b-edge.a).cross(next.b-next.a) <= 0.001:
				continue
			var normal: Vector2 = (edge.normal + next.normal).normalized()
			var point: Vector2 = edge.b + normal * clearance / maxf(normal.dot(edge.normal), 0.1)
			if inside(point):
				continue
			var duplicate := false
			for corner in corners:
				if corner.position.distance_to(point) < 0.001:
					duplicate = true
			if not duplicate:
				corners.append({"position": point, "vertex": edge.b, "normal": normal})
	corners.sort_custom(func(a: Dictionary, b: Dictionary): return a.position.x < b.position.x if not is_equal_approx(a.position.x, b.position.x) else a.position.y < b.position.y)

func visible(a: Vector2, b: Vector2, margin := 0.0) -> bool:
	if a.distance_to(b) < 0.001:
		return true
	for polygon in polygons:
		var tests: Array[PackedVector2Array] = [polygon]
		if margin > 0.0:
			tests = []
			for expanded in Geometry2D.offset_polygon(polygon, margin, Geometry2D.JOIN_MITER):
				tests.append(expanded)
		for test in tests:
			var direction := (b-a).normalized()
			# Only boundary endpoints get a tolerance, never an entire collider.
			var start := a
			var end := b
			if _boundary_distance(a, polygon) <= margin + 0.01:
				start += direction * minf(margin * 3.0 + 0.02, a.distance_to(b) * 0.1)
			if _boundary_distance(b, polygon) <= margin + 0.01:
				end -= direction * minf(margin * 3.0 + 0.02, a.distance_to(b) * 0.1)
			var cuts: Array[float] = [0.0, 1.0]
			for i in test.size():
				var hit = Geometry2D.segment_intersects_segment(start, end, test[i], test[(i+1)%test.size()])
				if hit != null:
					cuts.append(start.distance_to(hit) / maxf(start.distance_to(end), 0.001))
			cuts.sort()
			for i in range(cuts.size()-1):
				if cuts[i+1] - cuts[i] > 0.000001 and _contains(start.lerp(end, (cuts[i]+cuts[i+1])/2), test):
					return false
	return true

func _boundary_distance(point: Vector2, polygon: PackedVector2Array) -> float:
	var distance := INF
	for i in polygon.size():
		distance = minf(distance, Geometry2D.get_closest_point_to_segment(point, polygon[i], polygon[(i+1)%polygon.size()]).distance_to(point))
	return distance

func _contains(point: Vector2, polygon: PackedVector2Array) -> bool:
	# All registered polygons are convex and counterclockwise. Work relative to
	# each edge; absolute-coordinate ray parity loses boundary precision far from 0.
	for i in polygon.size():
		var edge := polygon[(i + 1) % polygon.size()] - polygon[i]
		var relative := point - polygon[i]
		if float(edge.x) * float(relative.y) - float(edge.y) * float(relative.x) < -0.00001:
			return false
	return true

extends SceneTree
const Path = preload("res://scripts/gum_path.gd")
const Geometry = preload("res://scripts/gum_terrain_geometry.gd")
var failures := 0
var world: Node2D
var settings = load("res://resources/game_settings.tres").duplicate()

func _initialize() -> void:
	call_deferred("verify")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func rectangle(center: Vector2, size: Vector2, parent: Node = null) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = center
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	(parent if parent != null else world).add_child(body)
	return body

func safe(path, a: Vector2, b: Vector2) -> bool:
	var ok: bool = path.update(a,b,world,settings)
	if ok:
		for i in range(path.points.size()-1):
			check(path.geometry.visible(path.points[i],path.points[i+1]), "Resolved segment must not cross terrain")
	return ok

func verify() -> void:
	world = Node2D.new()
	root.add_child(world)
	var obstacle := rectangle(Vector2.ZERO,Vector2(40,40))
	for rotation in 4:
		var angle := rotation * PI / 2
		var path = Path.new()
		var a := Vector2(-100,-60).rotated(angle)
		var b := Vector2(100,-60).rotated(angle)
		path.reset(a,b)
		check(safe(path,a,b), "Clear initial path")
		a = Vector2(-100,0).rotated(angle)
		b = Vector2(100,0).rotated(angle)
		check(safe(path,a,b) and path.pivots.size() == 2, "Four-sided two-corner wrapping")
		check(path.length > a.distance_to(b), "Path length includes detour")
		var total: Vector2 = path.start_direction()*100 - path.end_direction()*100
		for force in path.reactions(100):
			total += force
		check(total.length() < 0.001, "Endpoint plus terrain forces balance")
		var va := Vector2(12,-30)
		var vb := Vector2(-8,17)
		var shifted: PackedVector2Array = path.points.duplicate()
		shifted[0] += va * 0.0001
		shifted[-1] += vb * 0.0001
		var length := 0.0
		for i in range(shifted.size()-1):
			length += shifted[i].distance_to(shifted[i+1])
		check(absf((length-path.length)/0.0001-path.speed(va,vb)) < 0.5, "Analytical path speed matches finite displacement")
		for tick in 300:
			check(safe(path,a+Vector2(0.02 if tick%2 else -0.02,0).rotated(angle),b), "Stable repeated path update")
			check(path.pivots.size() == 2 and is_finite(path.length), "No pivot proliferation or oscillation")
		a = Vector2(-100,-60).rotated(angle)
		b = Vector2(100,-60).rotated(angle)
		for tick in 4:
			check(safe(path,a,b), "Return route remains valid")
		check(path.pivots.is_empty(), "Clear shortcut unwraps")
	var geometry = Geometry.new()
	geometry.refresh(world,1)
	check(geometry.corners.size() == 4, "Single rectangle has four convex corners")
	var neighbor := rectangle(Vector2(40,0),Vector2(40,40))
	geometry.refresh(world,1)
	check(geometry.corners.size() == 4, "Shared rectangle boundary contributes no pivots")
	neighbor.position = Vector2(20,20)
	geometry.refresh(world,1)
	check(geometry.corners.size() == 6, "Overlapping union exposes only six convex corners")
	neighbor.free()
	var path = Path.new()
	path.reset(Vector2(-100,-60),Vector2(100,-60))
	check(safe(path,Vector2(-100,60),Vector2(100,60)), "Fast sweep wraps even when final chord is clear")
	check(not path.pivots.is_empty(), "Sweep retains crossed obstacle topology")
	obstacle.free()
	check(safe(path,Vector2(-100,60),Vector2(100,60)) and path.pivots.is_empty(), "Deleted terrain removes stale pivots")
	obstacle = rectangle(Vector2.ZERO,Vector2(40,40))
	path.reset(Vector2(-100,0),Vector2(100,0))
	settings.wrap_max_pivots = 1
	check(not path.update(Vector2(-100,0),Vector2(100,0),world,settings) and path.failure == "PATH LIMIT", "Pivot budget safely fails")
	settings.wrap_max_pivots = 16
	path.reset(Vector2.ZERO,Vector2(100,0))
	check(not path.update(Vector2.ZERO,Vector2(100,0),world,settings) and path.failure == "PATH INVALID", "Embedded endpoint safely fails")
	path.reset(Vector2(-100,0),Vector2(100,0))
	settings.wrap_max_repairs = 0
	check(not path.update(Vector2(-100,0),Vector2(100,0),world,settings) and path.failure == "PATH LIMIT", "Repair budget safely fails")
	settings.wrap_max_repairs = 32
	var second := rectangle(Vector2(80,0),Vector2(30,70))
	path.reset(Vector2(-100,-100),Vector2(180,-100))
	check(safe(path,Vector2(-100,0),Vector2(180,0)) and path.pivots.size() >= 2, "Multiple obstacles preserve a valid detour")
	second.free()
	var shape := obstacle.get_child(0) as CollisionShape2D
	shape.shape = CircleShape2D.new()
	path.reset(Vector2(-100,0),Vector2(100,0))
	check(not path.update(Vector2(-100,0),Vector2(100,0),world,settings) and path.failure == "UNSUPPORTED OBSTACLE", "Unsupported geometry is explicit")
	obstacle.free()
	# A ring has an inner boundary but no inner convex solid corners.
	var ring: Array[StaticBody2D] = []
	ring.append(rectangle(Vector2(0,-40),Vector2(100,20)))
	ring.append(rectangle(Vector2(0,40),Vector2(100,20)))
	ring.append(rectangle(Vector2(-40,0),Vector2(20,60)))
	ring.append(rectangle(Vector2(40,0),Vector2(20,60)))
	geometry.refresh(world,1)
	check(geometry.corners.size() == 4 and not geometry.inside(Vector2.ZERO), "Union preserves hole and excludes concave inner corners")
	check(geometry.visible(Vector2(-20,0),Vector2(20,0)), "Path inside hole stays free")
	check(not geometry.visible(Vector2.ZERO,Vector2(100,0)), "Hole boundary blocks passage")
	world.free()
	world = load("res://scenes/stages/theater_stage.tscn").instantiate()
	root.add_child(world)
	var started := Time.get_ticks_usec()
	geometry.refresh(world,1)
	var build_ms := (Time.get_ticks_usec()-started)/1000.0
	check(not geometry.unsupported and geometry.corners.size() > 0, "Saved map exposes supported collision-derived corners")
	path = Path.new()
	path.reset(Vector2(160,586),Vector2(160,128))
	started = Time.get_ticks_usec()
	for tick in 300:
		check(safe(path,Vector2(160,586),Vector2(160,128)), "Saved-map steady path")
	print("Map geometry %.2f ms; steady path %.3f ms/tick; %d corners" % [build_ms,(Time.get_ticks_usec()-started)/300000.0,geometry.corners.size()])
	world.free()
	if failures == 0:
		print("PASS: four-sided wrapping/unwrap, stable pivots, union/shared edges, swept endpoints, deletion, budgets, path derivative, terrain force balance and saved map")
	quit(1 if failures else 0)

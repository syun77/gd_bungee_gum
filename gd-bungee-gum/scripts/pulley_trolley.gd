extends Node2D
## Each fresh adhesion requests one motor-driven rail segment; gum forces remain physical.
enum RouteMode { LOOP, PING_PONG }

@export var rail_texture: Texture2D
@export var route_points := PackedVector2Array([Vector2(80, 0), Vector2(184, 0), Vector2(288, 0)])
@export var route_mode := RouteMode.PING_PONG
@export_range(1.0, 1000.0) var travel_speed := 140.0
@export_range(1.0, 100000.0) var maximum_motor_force := 18000.0

const POSITION_RESPONSE := 20.0
const VELOCITY_RESPONSE := 40.0
const ARRIVAL_DISTANCE := 3.0
const ARRIVAL_SPEED := 8.0
const RAIL_HEIGHT := 8.32
const RAIL_OVERHANG := 20.0

@onready var carriage: RigidBody2D = $Carriage
@onready var guide: GrooveJoint2D = $Guide
var current_point := 0
var destination_point := 0
var direction := 1
var moving := false
var gum: Node2D
var points := PackedVector2Array()

func _ready() -> void:
	# A repeated closing point is implicit in LOOP; coincident neighbors have no segment.
	for point in route_points:
		if points.is_empty() or not point.is_equal_approx(points[-1]):
			points.append(point)
	if points.size() > 1 and points[0].is_equal_approx(points[-1]):
		points.remove_at(points.size() - 1)
	if points.size() < 2:
		push_warning("Pulley route requires at least two distinct points")
		set_physics_process(false)
		return
	carriage.position = points[0]
	_build_rails()
	_set_guide(points[0], points[1])

func bind(connection: Node2D) -> void:
	if is_instance_valid(gum) and gum.adhesion_started.is_connected(_on_adhesion_started):
		gum.adhesion_started.disconnect(_on_adhesion_started)
	gum = connection
	gum.adhesion_started.connect(_on_adhesion_started)

func _on_adhesion_started(_normal: Vector2, _is_ring: bool) -> void:
	if gum.target != carriage or moving or points.size() < 2:
		return
	if route_mode == RouteMode.LOOP:
		destination_point = (current_point + 1) % points.size()
	else:
		if current_point + direction < 0 or current_point + direction >= points.size():
			direction = -direction
		destination_point = current_point + direction
	_set_guide(carriage.position, points[destination_point])
	moving = true
	carriage.sleeping = false

func _physics_process(_delta: float) -> void:
	var offset := to_global(points[destination_point]) - carriage.global_position
	if moving and offset.length() <= ARRIVAL_DISTANCE and carriage.linear_velocity.length() <= ARRIVAL_SPEED:
		current_point = destination_point
		moving = false
	# Servo force drives/holds the physical body without overwriting velocity or position.
	var desired_velocity := (offset * POSITION_RESPONSE).limit_length(travel_speed)
	var force := (desired_velocity - carriage.linear_velocity) * carriage.mass * VELOCITY_RESPONSE
	carriage.apply_central_force(force.limit_length(maximum_motor_force))

func _set_guide(start: Vector2, end: Vector2) -> void:
	# Rebind the native constraint around the current body center at each departure.
	guide.node_a = NodePath()
	guide.node_b = NodePath()
	guide.position = start
	guide.rotation = (end - start).angle() - PI / 2.0
	guide.length = maxf(start.distance_to(end), 0.01)
	guide.initial_offset = 0.0
	guide.node_a = guide.get_path_to($RailSupport)
	guide.node_b = guide.get_path_to(carriage)

func _build_rails() -> void:
	var segment_count := points.size() if route_mode == RouteMode.LOOP else points.size() - 1
	for index in segment_count:
		var start := points[index]
		var end := points[(index + 1) % points.size()]
		var rail := Sprite2D.new()
		rail.texture = rail_texture
		rail.position = (start + end) / 2.0
		rail.rotation = (end - start).angle()
		rail.scale = Vector2((start.distance_to(end) + RAIL_OVERHANG * 2.0) / rail_texture.get_width(), RAIL_HEIGHT / rail_texture.get_height())
		$Rails.add_child(rail)

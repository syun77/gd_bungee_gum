extends Sprite2D
## Contact sensing and presentation; Game owns the gameplay lock and completion.
signal player_entered
const APPROACH_SPEED := 120.0
const REAR_POSE := &"exit_back"
const REAR_TEXTURE := preload("res://assets/characters/teto_back_exit.png")
const OPEN_TIME := 0.40
const FADE_TIME := 0.50
const CLOSE_TIME := 0.40
const TOTAL_TIME := OPEN_TIME + FADE_TIME + CLOSE_TIME
var elapsed := 0.0
var active := false
var started := false
var approaching := false
var settling := false
var fall_speed := 0.0
var body: CharacterBody2D
var actor: AnimatedSprite2D
var actor_color := Color.WHITE

func _init() -> void:
	texture = preload("res://assets/stage/restaurant_stage_exit.png")
	hframes = 3
	vframes = 2
	offset = Vector2(0, -64)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _ready() -> void:
	var trigger := Area2D.new()
	trigger.name = "Contact"
	trigger.collision_layer = 0
	trigger.collision_mask = 2
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 64)
	collider.shape = shape
	collider.position.y = -32
	trigger.add_child(collider)
	add_child(trigger)
	trigger.body_entered.connect(func(body: Node2D):
		if body.is_in_group("player") and not started:
			player_entered.emit())

func begin(player: CharacterBody2D, vertical_speed := 0.0) -> void:
	if started:
		return
	started = true
	active = true
	body = player
	actor = body.get_node("AnimatedSprite2D")
	actor_color = actor.self_modulate
	settling = true
	fall_speed = vertical_speed
	approaching = false
	actor.scale = body.sprite_rest_scale
	actor.position = body.sprite_rest_position
	actor.rotation = 0.0
	actor.flip_h = body.global_position.x > global_position.x
	actor.play(&"jump")
	actor.pause()
	actor.frame = 2 if fall_speed < -80.0 else 5
	if not actor.sprite_frames.has_animation(REAR_POSE):
		actor.sprite_frames.add_animation(REAR_POSE)
		actor.sprite_frames.add_frame(REAR_POSE, REAR_TEXTURE)
	elapsed = 0.0
	frame = 0

func step(delta: float) -> void:
	if not active:
		return
	if settling:
		_step_landing(delta)
		return
	if approaching:
		_step_approach(delta)
		return
	var previous_elapsed := elapsed
	elapsed = minf(elapsed + delta, TOTAL_TIME)
	if previous_elapsed <= 0.0 and elapsed > 0.0:
		get_node("/root/SoundEffects").play(&"door_open")
	if elapsed < OPEN_TIME:
		frame = mini(5, int(elapsed / OPEN_TIME * 6.0))
	elif elapsed < OPEN_TIME + FADE_TIME:
		frame = 5
		var progress := (elapsed - OPEN_TIME) / FADE_TIME
		actor.self_modulate = actor_color.lerp(Color(0, 0, 0, actor_color.a), progress)
	else:
		actor.self_modulate = Color(0, 0, 0, actor_color.a)
		actor.hide()
		var progress := (elapsed - OPEN_TIME - FADE_TIME) / CLOSE_TIME
		frame = maxi(0, 5 - int(progress * 6.0))
	if elapsed >= TOTAL_TIME:
		get_node("/root/SoundEffects").play(&"door_close")
		frame = 0
		active = false

func _step_approach(delta: float) -> void:
	var offset_to_door := Vector2(global_position.x - body.global_position.x, 0.0)
	if absf(offset_to_door.x) > 0.5:
		actor.flip_h = offset_to_door.x < 0.0
	var motion := offset_to_door.limit_length(APPROACH_SPEED * delta)
	for slide in 4:
		var collision := body.move_and_collide(motion)
		if collision == null:
			break
		motion = collision.get_remainder().slide(collision.get_normal())
		if motion.is_zero_approx():
			break
	if absf(body.global_position.x - global_position.x) <= 0.5:
		approaching = false
		actor.flip_h = false
		actor.play(REAR_POSE)
		actor.pause()

func _step_landing(delta: float) -> void:
	fall_speed += body.settings.gravity * delta
	actor.frame = 2 if fall_speed < -80.0 else (3 if fall_speed < 80.0 else 5)
	var collision := body.move_and_collide(Vector2(0, fall_speed * delta))
	if collision == null:
		return
	fall_speed = 0.0
	if collision.get_normal().dot(Vector2.UP) >= cos(body.floor_max_angle):
		settling = false
		approaching = true
		actor.play(&"run")

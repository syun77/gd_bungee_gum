extends Sprite2D
## Contact sensing and presentation; Game owns the gameplay lock and completion.
signal player_entered
const OPEN_TIME := 0.40
const FADE_TIME := 0.50
const CLOSE_TIME := 0.40
const TOTAL_TIME := OPEN_TIME + FADE_TIME + CLOSE_TIME
var elapsed := 0.0
var active := false
var started := false
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

func begin(sprite: AnimatedSprite2D) -> void:
	if started:
		return
	started = true
	active = true
	actor = sprite
	actor_color = actor.self_modulate
	actor.play(&"idle")
	elapsed = 0.0
	frame = 0

func step(delta: float) -> void:
	if not active:
		return
	elapsed = minf(elapsed + delta, TOTAL_TIME)
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
		frame = 0
		active = false

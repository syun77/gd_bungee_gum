extends Sprite2D
## Presentation only; Game owns the movement lock and advances this timeline.
const CLOSED_HOLD := 0.20
const OPEN_TIME := 0.40
const EMERGE_TIME := 0.50
const TOTAL_TIME := CLOSED_HOLD + OPEN_TIME + EMERGE_TIME
const FRONT_POSE := &"entrance_front"
const FRONT_TEXTURE := preload("res://assets/characters/teto_front_entrance.png")
var elapsed := 0.0
var active := false
var actor: AnimatedSprite2D
var actor_color := Color.WHITE

func _init() -> void:
	texture = preload("res://assets/stage/restaurant_stage_entrance.png")
	hframes = 3
	vframes = 2
	offset = Vector2(0, -64)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func begin(sprite: AnimatedSprite2D) -> void:
	actor = sprite
	actor_color = actor.self_modulate
	elapsed = 0.0
	active = true
	frame = 0
	actor.hide()
	actor.self_modulate = Color(0, 0, 0, actor_color.a)
	if not actor.sprite_frames.has_animation(FRONT_POSE):
		actor.sprite_frames.add_animation(FRONT_POSE)
		actor.sprite_frames.add_frame(FRONT_POSE, FRONT_TEXTURE)
	actor.flip_h = false
	actor.play(FRONT_POSE)
	actor.pause()

func step(delta: float) -> void:
	if not active:
		return
	elapsed = minf(elapsed + delta, TOTAL_TIME)
	if elapsed < CLOSED_HOLD:
		frame = 0
	elif elapsed < CLOSED_HOLD + OPEN_TIME:
		frame = mini(5, int((elapsed - CLOSED_HOLD) / OPEN_TIME * 6.0))
	else:
		var progress := clampf((elapsed - CLOSED_HOLD - OPEN_TIME) / EMERGE_TIME, 0.0, 1.0)
		actor.show()
		actor.self_modulate = Color.BLACK.lerp(actor_color, progress)
		actor.self_modulate.a = actor_color.a
		frame = maxi(0, 5 - int(progress * 6.0))
	if elapsed >= TOTAL_TIME:
		active = false
		frame = 0
		actor.self_modulate = actor_color
		actor.play(&"idle")
		actor.show()

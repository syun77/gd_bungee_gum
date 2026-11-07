extends Sprite2D
## PixelFX debris stays at the destroyed cell center and never participates in physics.
const SHEET = preload("res://assets/effects/brick_break.png")
const FPS := 30.0
const DURATION := 0.5
var elapsed := 0.0

func _init() -> void:
	texture = SHEET
	hframes = 4
	vframes = 4
	offset = Vector2(0, 8)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 7
	z_as_relative = false
	top_level = true
	add_to_group("brick_break_effects")

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= DURATION:
		queue_free()
	else:
		frame = int(elapsed * FPS)

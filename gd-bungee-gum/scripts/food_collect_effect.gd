extends Sprite2D
## Frozen world-space PixelFX burst; the stage owns its lifetime after pickup deletion.
const SHEET = preload("res://assets/effects/food_collect.png")
const DURATION := 0.7
const FPS := 30.0
var elapsed := 0.0

func _init() -> void:
	texture = SHEET
	hframes = 5
	vframes = 5
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 7
	z_as_relative = false
	top_level = true
	add_to_group("food_collect_effects")

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= DURATION:
		queue_free()
	else:
		frame = mini(int(elapsed * FPS), 20)

extends Sprite2D
## Art-only availability loop; owned by the collectible throughout its lifetime.
const SHEET = preload("res://assets/effects/food_idle.png")
const DURATION := 2.0
const FPS := 30.0
var elapsed := 0.0

func _ready() -> void:
	texture = SHEET
	hframes = 10
	vframes = 6
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Stable position-based phases keep nearby dishes from blinking together.
	elapsed = float(hash(global_position) % 6000) / 3000.0
	_update_frame()

func _process(delta: float) -> void:
	elapsed = fposmod(elapsed + delta, DURATION)
	_update_frame()

func _update_frame() -> void:
	frame = mini(int(elapsed * FPS), 59)

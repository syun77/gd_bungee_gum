extends Sprite2D
## PixelFX playback at a frozen world-space body center, owned by Game's fixed step.
const SHEET = preload("res://assets/effects/player_disappear.png")
const DURATION := 0.6
var elapsed := 0.0

func _init() -> void:
	texture = SHEET
	hframes = 5
	vframes = 4
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 8
	z_as_relative = false

func step(delta: float) -> bool:
	elapsed = minf(elapsed + delta, DURATION)
	frame = mini(int(elapsed * 30.0), 18)
	return elapsed >= DURATION

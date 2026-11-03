extends Node2D
## Presentation only: a sparse idle loop and a single activation burst.
const IDLE = preload("res://assets/effects/checkpoint_idle.png")
const ACTIVE = preload("res://assets/effects/checkpoint_active.png")
const BURST = preload("res://assets/effects/checkpoint_activate.png")
const FPS := 30.0
const LOOP_SECONDS := 2.0
const BURST_SECONDS := 0.8
var loop_elapsed := 0.0
var burst_elapsed := 0.0
var burst_playing := false
var idle: Sprite2D
var burst: Sprite2D

func _ready() -> void:
	idle = _make_sprite(IDLE, 10, 6, Vector2(0, -32))
	burst = _make_sprite(BURST, 5, 5, Vector2(0, -32))
	burst.hide()

func _make_sprite(atlas: Texture2D, columns: int, rows: int, offset: Vector2) -> Sprite2D:
	var artwork := Sprite2D.new()
	artwork.texture = atlas
	artwork.hframes = columns
	artwork.vframes = rows
	artwork.position = offset
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(artwork)
	return artwork

func activate(animate: bool) -> void:
	idle.texture = ACTIVE
	loop_elapsed = 0.0
	idle.frame = 0
	burst_elapsed = 0.0
	burst_playing = animate
	burst.frame = 0
	burst.visible = animate
	idle.visible = not animate

func _process(delta: float) -> void:
	loop_elapsed = fposmod(loop_elapsed + delta, LOOP_SECONDS)
	idle.frame = mini(int(loop_elapsed * FPS), 59)
	if burst_playing:
		burst_elapsed += delta
		burst_playing = burst_elapsed < BURST_SECONDS
		burst.frame = mini(int(burst_elapsed * FPS), 24)
		burst.visible = burst_playing
		idle.visible = not burst_playing

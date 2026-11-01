extends Node2D
## Standalone map inspection camera; gameplay uses game.tscn.

@onready var camera: Camera2D = $Camera2D
var overview := false

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_6:
		overview = false
		camera.zoom = Vector2.ONE
		camera.position = Vector2(512 + (event.keycode - KEY_1) * 832, 384)
	elif event.keycode == KEY_TAB:
		overview = not overview
		camera.zoom = Vector2(0.235, 0.235) if overview else Vector2.ONE
		camera.position = Vector2(2560, 384) if overview else Vector2(512, 384)
	elif event.keycode == KEY_HOME:
		camera.position = Vector2(512, 384)
		camera.zoom = Vector2.ONE
		overview = false

func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	camera.position += direction * 720.0 * delta / camera.zoom.x
	camera.position = camera.position.clamp(Vector2(320, 128), Vector2(4800, 640))

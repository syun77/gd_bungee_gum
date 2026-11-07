extends Node2D
## Render recorded state without creating players, collectible areas or rigid bodies.
const Settings = preload("res://scripts/game_settings.gd")
@export var settings: Settings
var visuals: Dictionary = {}
var cursor := 0
var clock := 0.0
var finished := false
var camera: Camera2D
var status: Label
var score: Label
var timer: Label
var pause_menu: CanvasLayer

func _ready() -> void:
	camera = Camera2D.new()
	add_child(camera)
	var hud := CanvasLayer.new()
	add_child(hud)
	score = Label.new()
	score.position = Vector2(24, 16)
	score.theme = preload("res://resources/hud_score_theme.tres")
	hud.add_child(score)
	timer = Label.new()
	timer.position = Vector2(24, 112)
	timer.theme = preload("res://resources/hud_timer_theme.tres")
	hud.add_child(timer)
	status = Label.new()
	status.position = Vector2(24, 64)
	status.text = "REPLAY  |  Esc / OPTIONS: メニュー"
	hud.add_child(status)
	pause_menu = preload("res://scripts/pause_menu.gd").new()
	add_child(pause_menu)
	pause_menu.buttons[0].text = "最初から再生"
	pause_menu.buttons[1].text = "戻る"
	pause_menu.retry_requested.connect(_restart)
	pause_menu.selection_requested.connect(_back)
	if not ReplayStore.available():
		_back()
		return
	_apply_frame(ReplayStore.latest.frames[0])
	cursor = 1

func _physics_process(delta: float) -> void:
	if finished or not ReplayStore.available():
		return
	clock += delta
	var step := 1.0 / float(ReplayStore.latest.tick_rate)
	while clock >= step and cursor < ReplayStore.latest.frames.size():
		clock -= step
		_apply_frame(ReplayStore.latest.frames[cursor])
		cursor += 1
	if cursor >= ReplayStore.latest.frames.size():
		finished = true
		status.text = "REPLAY END  |  Esc / OPTIONS: メニュー"
		pause_menu.open()

func _apply_frame(frame: Dictionary) -> void:
	for id in frame.removed:
		if visuals.has(id):
			visuals[id].free()
			visuals.erase(id)
	for id in frame.changed:
		var data: Dictionary = frame.changed[id]
		if not visuals.has(id):
			visuals[id] = _create_visual(data)
			add_child(visuals[id])
		var node: Node2D = visuals[id]
		node.transform = data.transform
		node.modulate = data.modulate
		node.z_index = data.z
		if data.has("uniforms"):
			for uniform in data.uniforms:
				node.material.set_shader_parameter(uniform, data.uniforms[uniform])
		match data.kind:
			"label":
				var label: Label = node.get_child(0)
				label.text = data.text
				label.size = data.size
			"particles":
				node.circles = data.circles
				node.queue_redraw()
			"gum":
				node.data = data
				node.queue_redraw()
			"sprite":
				node.texture = load(data.texture)
				node.region_enabled = true
				node.region_rect = data.region
				node.offset = data.offset
				node.centered = data.centered
				node.flip_h = data.flip_h
				node.flip_v = data.flip_v
			"tiles":
				node.tile_map_data = data.cells
			"line":
				node.points = data.points
				node.width = data.width
				node.default_color = data.color
				node.closed = data.get("closed", false)
			"polygon":
				node.polygon = data.points
				node.color = data.color
	for cue in frame.sounds:
		SoundEffects.play(cue)
	camera.position = frame.camera
	camera.zoom = Vector2.ONE * settings.camera_normal_zoom
	camera.reset_smoothing()
	score.text = "SCORE %d" % frame.score
	timer.visible = frame.time_attack
	timer.text = "TIME %.2f" % frame.elapsed

func _create_visual(data: Dictionary) -> Node2D:
	var node: Node2D
	match data.kind:
		"particles": node = preload("res://scripts/replay_particles.gd").new()
		"label":
			node = Node2D.new()
			var label := Label.new()
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if not data.theme.is_empty():
				label.theme = load(data.theme)
			node.add_child(label)
		"gum": node = preload("res://scripts/replay_gum.gd").new()
		"sprite": node = Sprite2D.new()
		"line": node = Line2D.new()
		"polygon": node = Polygon2D.new()
		"tiles":
			var layer := TileMapLayer.new()
			# Use atlas sources only; scene tiles must never instantiate live gameplay.
			layer.tile_set = load(data.tileset).duplicate()
			for i in range(layer.tile_set.get_source_count() - 1, -1, -1):
				var id := layer.tile_set.get_source_id(i)
				if layer.tile_set.get_source(id) is TileSetScenesCollectionSource:
					layer.tile_set.remove_source(id)
			layer.collision_enabled = false
			layer.navigation_enabled = false
			node = layer
	if data.has("shader"):
		var material := ShaderMaterial.new()
		material.shader = load(data.shader)
		node.material = material
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return node

func _restart() -> void:
	pause_menu.close()
	get_tree().reload_current_scene()

func _back() -> void:
	pause_menu.close()
	get_tree().change_scene_to_file(ReplayStore.return_scene)

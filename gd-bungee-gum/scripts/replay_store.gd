extends Node
## Visual fixed-step recording: playback never runs gameplay or physics.
const SAVE_PATH := "user://latest_replay.dat"
const FORMAT_VERSION := 1
var save_path := SAVE_PATH
var sounds: Array = []
var frames: Array = []
var previous: Dictionary = {}
var game: Node2D
var continuing := false
var latest: Dictionary = {}
var return_scene := "res://scenes/mode_select.tscn"
var recording_scene := ""
var failure := ""

func _ready() -> void:
	process_physics_priority = 100
	load_latest()

func load_latest() -> void:
	latest = {}
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open_compressed(save_path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if file == null:
		push_warning("Cannot open replay: %s" % error_string(FileAccess.get_open_error()))
		return
	var data = file.get_var(false)
	if valid_recording(data):
		latest = data
	else:
		push_warning("Replay is invalid or uses an unsupported format")

func begin(host: Node2D) -> void:
	if not continuing or recording_scene != host.scene_file_path:
		frames = []
		previous = {}
		recording_scene = host.scene_file_path
		failure = ""
		sounds = []
	continuing = false
	game = host
	if not SoundEffects.played.is_connected(_on_sound):
		SoundEffects.played.connect(_on_sound)
	capture()

func _physics_process(_delta: float) -> void:
	if is_instance_valid(game) and not game.restarting:
		capture()

func suspend(keep_run: bool) -> void:
	# Scene reloads allocate new instance IDs; the next snapshot removes old visuals.
	continuing = keep_run
	game = null
	if not keep_run:
		frames = []
		previous = {}
		sounds = []

func _on_sound(cue: StringName) -> void:
	if is_instance_valid(game) or continuing:
		sounds.append(cue)

func capture() -> void:
	if not is_instance_valid(game):
		return
	var visuals: Dictionary = {}
	_collect(game, visuals)
	var gum_data: Dictionary = game.gum.replay_visual()
	if not gum_data.is_empty():
		visuals[-1] = gum_data
	var changed: Dictionary = {}
	var removed: Array = []
	for id in visuals:
		if not previous.has(id) or previous[id] != visuals[id]:
			changed[id] = visuals[id]
	for id in previous:
		if not visuals.has(id):
			removed.append(id)
	frames.append({"changed": changed, "removed": removed,
		"camera": game.camera.get_screen_center_position(),
		"score": game.score, "elapsed": game.elapsed, "time_attack": game.time_attack, "sounds": sounds.duplicate()})
	sounds.clear()
	previous = visuals

func finish() -> void:
	capture()
	game = null
	continuing = false
	if frames.is_empty():
		return
	var data := {"version": FORMAT_VERSION, "scene": recording_scene,
		"tick_rate": Engine.physics_ticks_per_second, "frames": frames}
	var temporary := save_path + ".tmp"
	var file := FileAccess.open_compressed(temporary, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if file == null:
		_save_failed(FileAccess.get_open_error())
		return
	file.store_var(data, false)
	file.flush()
	var error := file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(temporary, save_path)
	if error != OK:
		_save_failed(error)
		return
	latest = data
	frames = []
	previous = {}

func _save_failed(error: Error) -> void:
	failure = "リプレイの保存に失敗しました"
	push_warning("Cannot save replay: %s" % error_string(error))

func available() -> bool:
	return not latest.is_empty()

func play(back_to: String) -> void:
	if not available():
		return
	return_scene = back_to
	suspend(false)
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", "res://scenes/replay.tscn")

func _collect(node: Node, result: Dictionary) -> void:
	if node is CanvasLayer:
		return
	if node is CanvasItem and not node.is_visible_in_tree():
		return
	var data: Dictionary = {}
	if node.has_method("replay_particles"):
		data = {"kind": "particles", "circles": node.replay_particles()}
	elif node is Label:
		data = {"kind": "label", "text": node.text, "theme": node.theme.resource_path if node.theme != null else "", "size": node.size}
	elif node is Sprite2D and node.texture != null:
		var size: Vector2 = node.texture.get_size() / Vector2(node.hframes, node.vframes)
		var region: Rect2 = node.region_rect if node.region_enabled else Rect2(Vector2(node.frame_coords) * size, size)
		data = _sprite(node, node.texture, region)
	elif node is AnimatedSprite2D and node.sprite_frames != null:
		var texture: Texture2D = node.sprite_frames.get_frame_texture(node.animation, node.frame)
		if texture != null:
			data = _sprite(node, texture, Rect2(Vector2.ZERO, texture.get_size()))
	elif node is TileMapLayer and node.tile_set != null:
		# Scene tiles are captured through their instantiated sprite children.
		var has_atlas := false
		for i in node.tile_set.get_source_count():
			if node.tile_set.get_source(node.tile_set.get_source_id(i)) is TileSetAtlasSource:
				has_atlas = true
		if has_atlas:
			data = {"kind": "tiles", "tileset": node.tile_set.resource_path, "cells": node.tile_map_data}
	elif node is Line2D:
		data = {"kind": "line", "points": node.points, "width": node.width, "color": node.default_color, "closed": node.closed}
	elif node is Polygon2D:
		data = {"kind": "polygon", "points": node.polygon, "color": node.color}
	if not data.is_empty():
		if node.material is ShaderMaterial and node.material.shader != null:
			data["shader"] = node.material.shader.resource_path
			var uniforms: Dictionary = {}
			for uniform in node.material.shader.get_shader_uniform_list():
				var value = node.material.get_shader_parameter(uniform.name)
				if value != null and not value is Object and not value is RID:
					uniforms[uniform.name] = value
			data["uniforms"] = uniforms
		data["transform"] = node.get_global_transform()
		data["modulate"] = _color(node)
		data["z"] = _z(node)
		result[node.get_instance_id()] = data
	for child in node.get_children():
		_collect(child, result)

func _sprite(node: Node2D, texture: Texture2D, region: Rect2) -> Dictionary:
	if texture is AtlasTexture:
		region.position += texture.region.position
		texture = texture.atlas
	if texture.resource_path.is_empty():
		return {}
	return {"kind": "sprite", "texture": texture.resource_path, "region": region,
		"offset": node.offset, "centered": node.centered, "flip_h": node.flip_h, "flip_v": node.flip_v}

func _color(node: CanvasItem) -> Color:
	var color := node.self_modulate * node.modulate
	var parent := node.get_parent()
	while parent is CanvasItem:
		color *= parent.modulate
		parent = parent.get_parent()
	return color

func _z(node: CanvasItem) -> int:
	var z := node.z_index
	while node.z_as_relative and node.get_parent() is CanvasItem:
		node = node.get_parent()
		z += node.z_index
	return z

func valid_recording(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != FORMAT_VERSION:
		return false
	if not data.get("frames") is Array or data.frames.is_empty():
		return false
	if not data.get("tick_rate") is int or data.tick_rate <= 0 or data.tick_rate > 1000:
		return false
	for frame in data.frames:
		if not frame is Dictionary or not frame.get("changed") is Dictionary or not frame.get("removed") is Array:
			return false
		if not frame.get("camera") is Vector2 or not frame.camera.is_finite():
			return false
		if not frame.get("score") is int or not frame.get("elapsed") is float or not frame.get("time_attack") is bool or not frame.get("sounds") is Array:
			return false
		for cue in frame.sounds:
			if not cue is StringName and not cue is String:
				return false
			if not SoundEffects.CLIPS.has(cue):
				return false
		for visual in frame.changed.values():
			if not _valid_visual(visual):
				return false
	return true

func _valid_visual(data: Variant) -> bool:
	if not data is Dictionary or not data.get("transform") is Transform2D or not data.get("modulate") is Color or not data.get("z") is int:
		return false
	var fields: Dictionary
	match data.get("kind"):
		"sprite": fields = {"texture": TYPE_STRING, "region": TYPE_RECT2, "offset": TYPE_VECTOR2, "centered": TYPE_BOOL, "flip_h": TYPE_BOOL, "flip_v": TYPE_BOOL}
		"tiles": fields = {"tileset": TYPE_STRING, "cells": TYPE_PACKED_BYTE_ARRAY}
		"line": fields = {"points": TYPE_PACKED_VECTOR2_ARRAY, "width": TYPE_FLOAT, "color": TYPE_COLOR}
		"polygon": fields = {"points": TYPE_PACKED_VECTOR2_ARRAY, "color": TYPE_COLOR}
		"label": fields = {"text": TYPE_STRING, "theme": TYPE_STRING, "size": TYPE_VECTOR2}
		"particles":
			if not data.get("circles") is Array:
				return false
			for circle in data.circles:
				if not circle is Array or circle.size() != 3 or not circle[0] is Vector2 or not circle[1] is float or not circle[2] is Color:
					return false
			return true
		"gum":
			fields = {"ready": TYPE_BOOL, "points": TYPE_PACKED_VECTOR2_ARRAY, "color": TYPE_COLOR, "width": TYPE_FLOAT, "pivots": TYPE_PACKED_VECTOR2_ARRAY, "endpoint": TYPE_VECTOR2, "glow_radius": TYPE_FLOAT, "glow_opacity": TYPE_FLOAT, "core": TYPE_FLOAT}
			if data.get("ready", false):
				fields.merge({"dash": TYPE_FLOAT, "reticle_radius": TYPE_FLOAT, "reticle_width": TYPE_FLOAT})
				if not data.get("points") is PackedVector2Array or data.points.size() < 2:
					return false
		_: return false
	for field in fields:
		if typeof(data.get(field)) != fields[field]:
			return false
	for field in ["texture", "tileset", "shader", "theme"]:
		if data.has(field) and (not data[field] is String or (not data[field].is_empty() and (not data[field].begins_with("res://") or not ResourceLoader.exists(data[field])))):
			return false
	return not data.has("uniforms") or data.uniforms is Dictionary

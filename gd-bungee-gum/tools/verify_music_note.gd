extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var preview = load("res://scenes/music_note_preview.tscn").instantiate()
	root.add_child(preview)
	var note = preview.get_node("NoteLeft")
	var other = preview.get_node("NoteRight")
	assert(note.sprite.texture.get_size() == Vector2(32, 32))
	assert(note.sprite.material != other.sprite.material, "Each note owns its highlight uniform")
	assert(not is_equal_approx(note.elapsed, other.elapsed), "Placed notes have independent phases")
	note.set_process(false)
	var original_transform: Transform2D = note.transform
	for time in [0.0, 1.2, 2.4, 3.0]:
		note.elapsed = time
		note._update_appearance()
		assert(is_zero_approx(note.sprite.material.get_shader_parameter("shine")), "Quiet interval has no highlight")
	note.elapsed = 2.7
	note._update_appearance()
	assert(is_equal_approx(note.sprite.material.get_shader_parameter("shine"), 1.0), "Peak at2.7s")
	note._process(0.3)
	assert(is_zero_approx(note.elapsed), "Loop wraps at3s")
	assert(note.transform == original_transform, "Animation preserves position/scale/rotation")
	var original_sprite: Transform2D = note.sprite.transform
	var pickup = note.get_node("CollisionShape2D")
	var original_sensor: Transform2D = pickup.transform
	for step in 241:
		note.turn_elapsed = step / 60.0
		note._update_appearance()
		var yaw: float = note.sprite.material.get_shader_parameter("yaw")
		assert(absf(yaw) <= deg_to_rad(32.0) + 0.0001)
		assert(maxf(0.94, lerpf(1.0, cos(yaw), 0.35)) >= 0.94, "Turn keeps a broad face")
		assert(note.sprite.transform == original_sprite and pickup.transform == original_sensor)
		assert(is_equal_approx(pickup.shape.radius, 18.0), "Pickup radius never follows visual yaw")
		if step == 60:
			assert(is_equal_approx(yaw, deg_to_rad(32.0)), "Right oblique at1s")
		if step == 180:
			assert(is_equal_approx(yaw, -deg_to_rad(32.0)), "Left oblique at3s")
	note.turn_elapsed = 3.9
	note._process(0.1)
	assert(is_zero_approx(note.turn_elapsed), "Turn repeats at4s")
	note.set_process(true)
	paused = true
	var frozen: float = note.elapsed
	var frozen_turn: float = note.turn_elapsed
	await process_frame
	await process_frame
	assert(note.elapsed == frozen and note.turn_elapsed == frozen_turn, "Pause freezes animation")
	paused = false
	await process_frame
	await process_frame
	assert(note.elapsed != frozen and note.turn_elapsed != frozen_turn, "Resume advances animation")
	print("Music note PASS: scene/texture/independent phases/quiet interval/peak/loop/readable yaw/fixed sensor/pause/resume")
	quit()

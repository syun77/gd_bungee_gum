extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("verify")
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1
func verify() -> void:
	var audio = root.get_node("SoundEffects")
	for cue in audio.CLIPS:
		var clip: AudioStreamWAV = audio.CLIPS[cue]
		check(clip.get_length() > 0.0 and clip.loop_mode == AudioStreamWAV.LOOP_DISABLED, "Valid one-shot %s" % cue)
		audio.play(cue)
	check(audio.get_child_count() == 8, "All eight cues overlap")
	for i in 30:
		audio.play(&"jump")
	check(audio.get_child_count() == 24, "Bounded voices")
	for voice in audio.get_children():
		audio.remove_child(voice)
		voice.queue_free()
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game._physics_process(game.entrance.TOTAL_TIME)
	current_scene = game
	game.set_physics_process(false)
	await physics_frame
	var gum = game.gum
	gum.state = gum.State.ATTACHED
	gum.target = game.get_node("PuzzleLightBox")
	gum.mode = gum.Mode.LOOSEN
	gum.contract()
	gum._play_contraction_sound()
	check(audio.get_child_count() == 1, "Contraction starts once")
	gum.contract()
	gum._play_contraction_sound()
	check(audio.get_child_count() == 1, "Repeated contract stays silent")
	gum.relax()
	gum.contract()
	gum._play_contraction_sound()
	check(audio.get_child_count() == 2, "Relax then contract sounds again")
	var checkpoint = game.get_node("TheaterStage/Checkpoints").get_child(0)
	game._on_checkpoint_reached(checkpoint)
	game._on_checkpoint_reached(checkpoint)
	check(audio.get_child_count() == 3, "Checkpoint first activation only")
	game._die_on_spikes(game.player.global_position)
	game._die_on_spikes(game.player.global_position)
	check(audio.get_child_count() == 4, "Death once")
	game.queue_free()
	await process_frame
	check(audio.get_child_count() == 4, "Audio survives scene removal")
	for voice in audio.get_children():
		voice.free()
	await process_frame
	print("Sound effects: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(failures)

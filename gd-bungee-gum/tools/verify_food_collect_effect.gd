extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("verify")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func verify() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var layer := Node2D.new()
	stage.add_child(layer)
	var food = load("res://scenes/items/foods/milano_doria.tscn").instantiate()
	layer.add_child(food)
	food.global_position = Vector2(200, 150)
	var idle = food.idle_effect
	idle.set_process(false)
	check(idle.visible and idle.texture.get_size() == Vector2(960, 576), "Food has the sliced availability sheet")
	var start_frame: int = idle.frame
	idle._process(2.0)
	check(idle.frame == start_frame, "Idle loops seamlessly after two seconds")
	food.being_pulled = true
	check(not idle.visible, "Reeling immediately hides idle")
	food.being_pulled = false
	check(idle.visible, "Cancelled reel restores availability")
	food.collect()
	check(not idle.visible, "Collected food stops idle before deletion")
	food.collect()
	var effects := get_nodes_in_group("food_collect_effects")
	check(effects.size() == 1, "Collection creates exactly one burst")
	var effect = effects[0]
	effect.set_process(false)
	await process_frame
	check(not is_instance_valid(food), "Food is deleted")
	check(is_instance_valid(effect), "Particles survive food deletion")
	check(effect.global_position == Vector2(200, 150), "Burst starts at collection position")
	stage.position += Vector2(40, 20)
	check(effect.global_position == Vector2(200, 150), "Burst is frozen in world space")
	check(effect.texture.get_size() == Vector2(560, 540), "Sheet dimensions match slicing")
	effect._process(0.2)
	check(effect.frame == 6, "Animation advances at30fps")
	effect._process(0.51)
	await process_frame
	check(not is_instance_valid(effect), "Burst expires")
	food = load("res://scenes/items/foods/milano_doria.tscn").instantiate()
	layer.add_child(food)
	food.collect()
	stage.queue_free()
	await process_frame
	check(get_nodes_in_group("food_collect_effects").is_empty(), "Stage deletion clears bursts")
	print("Food collect effect: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

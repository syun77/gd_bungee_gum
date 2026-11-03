extends SceneTree
## Saved/generated scenery parity and optional real-render review (-- --render).
const Decor = preload("res://scripts/background_decor.gd")
const Layout = preload("res://scripts/stage_layout.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func verify() -> void:
	var stage: Node2D = load("res://scenes/stages/theater_stage.tscn").instantiate()
	root.add_child(stage)
	var saved: TileMapLayer = stage.get_node("BackgroundDecor")
	var generated := Decor.create_layer()
	check(saved.get_used_cells().size() == Layout.BACKGROUND_DECOR.size(), "Saved decoration count matches authored layout")
	check(not saved.collision_enabled and saved.tile_set.get_physics_layers_count() == 0,
		"Decorations cannot collide or accept gum rays")
	check(saved.get_index() > stage.get_node("BackgroundIron").get_index()
		and saved.get_index() < stage.get_node("TerrainTiles").get_index(), "Decorations render between backdrop and terrain")
	check(saved.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Decorations use nearest filtering")
	check(saved.modulate == generated.modulate, "Saved tint matches generator")
	var atlas := saved.tile_set.get_source(0) as TileSetAtlasSource
	check(atlas.get_tiles_count() == 16 and atlas.texture.get_size() == Vector2(384, 384), "All16 normalized decorations are editor paintable")
	var used_ids := {}
	for placement in Layout.BACKGROUND_DECOR:
		var cell := Vector2i(placement.x, placement.y)
		var coords := Decor.atlas_coords(placement.z)
		used_ids[placement.z] = true
		check(saved.get_cell_source_id(cell) == generated.get_cell_source_id(cell)
			and saved.get_cell_atlas_coords(cell) == coords, "Saved stamp matches authoring helper at %s" % cell)
		check(atlas.get_tile_size_in_atlas(coords) == Vector2i(3, 3), "Stamp contains complete96px decoration")
		check(Rect2i(Vector2i.ZERO, Layout.SIZE).has_point(cell), "Decoration stays within stage")
	check(used_ids.size() == 16, "Stage showcases all16 decorations")
	generated.free()
	await process_frame
	if "--render" in OS.get_cmdline_user_args():
		root.size = Vector2i(1280, 768)
		var camera := Camera2D.new()
		camera.position = Vector2(640, 384)
		root.add_child(camera)
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(image.save_png("/tmp/restaurant-background-decor-stage.png") == OK, "Rendered stage capture saved")
		print("Rendered /tmp/restaurant-background-decor-stage.png")
	print("Background decoration verification: ", "PASS" if failures == 0 else "FAIL", " (42 placements /16 decorations)")
	stage.queue_free()
	quit(0 if failures == 0 else 1)

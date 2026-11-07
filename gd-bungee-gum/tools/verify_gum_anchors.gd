extends SceneTree
## Saved-map anchor ray, player/rigid passage, force, paint and erase lifecycle.
const Layout = preload("res://scripts/stage_layout.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func settle() -> void:
	for i in 3:
		await physics_frame
		await process_frame

func verify() -> void:
	var stage = load("res://scenes/stages/theater_stage.tscn").instantiate()
	root.add_child(stage)
	var anchors: TileMapLayer = stage.get_node("GumAnchors")
	check(anchors.physics_quadrant_size == 1, "Anchor bodies must identify individual cells")
	check(anchors.get_used_cells().size() == Layout.GUM_ANCHORS.size(), "Saved anchor placements")
	var player = load("res://scenes/characters/player.tscn").instantiate()
	root.add_child(player)
	var gum = load("res://scripts/gum_connection.gd").new()
	gum.settings = load("res://resources/game_settings.tres").duplicate()
	gum.settings.gum_diagnostics = false
	gum.player = player
	root.add_child(gum)
	var box = load("res://scenes/props/gum_box.tscn").instantiate()
	box.freeze = true
	root.add_child(box)
	await settle()
	for cell in Layout.GUM_ANCHORS:
		check(anchors.get_cell_source_id(cell) == 2 and anchors.get_cell_atlas_coords(cell) == Vector2i.ZERO,
			"Saved ring must use functional source2 at %s" % cell)
		var center := anchors.to_global(anchors.map_to_local(cell))
		var query := PhysicsRayQueryParameters2D.create(center + Vector2(0, 40), center, 16)
		var hit := anchors.get_world_2d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty() and hit.collider == anchors, "Saved ring generates attachment physics at %s" % cell)
		# Find an unobstructed approach without assuming authored surrounding terrain.
		var attached := false
		for direction in [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]:
			player.position = center + direction * 80 + Vector2(0, 34)
			if gum.attach_at(center) and gum.target == anchors:
				check(gum.endpoint().is_equal_approx(center), "Saved ring endpoint is its cell center at %s" % cell)
				attached = true
				break
			gum.detach("TEST")
		check(attached, "Saved ring has an accessible actual gum ray at %s" % cell)
		gum.detach("TEST")
	# Isolate passage/force/lifecycle from nearby terrain, using the saved TileSet.
	var fixture := TileMapLayer.new()
	fixture.tile_set = anchors.tile_set
	fixture.physics_quadrant_size = 1
	fixture.position = Vector2(10000, 0)
	fixture.set_cell(Vector2i.ZERO, 2, Vector2i.ZERO)
	root.add_child(fixture)
	anchors = fixture
	var center := anchors.to_global(anchors.map_to_local(Vector2i.ZERO))
	player.position = center + Vector2(0, 140)
	box.position = center + Vector2(80, 0)
	await settle()
	check(not player.test_move(Transform2D(0, center + Vector2(-40, 26)), Vector2(80, 0)), "Player passes through ring")
	check(not box.test_move(Transform2D(0, center + Vector2(-40, 0)), Vector2(80, 0)), "Rigid prop passes through ring")
	box.position = center + Vector2(200, 200)
	await settle()
	var tile := (anchors.tile_set.get_source(2) as TileSetAtlasSource).get_tile_data(Vector2i.ZERO, 0)
	check(tile.get_collision_polygon_points(1, 0) == PackedVector2Array(Layout.GUM_ANCHOR_POLYGON), "Saved adhesion bounds match authoring geometry")
	# Rays missing the artwork by5px still attach from all four directions.
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var tangent := Vector2(-direction.y, direction.x)
		var aim := center + tangent * 20
		player.position = aim - direction * 100 + Vector2(0, 34)
		check(gum.attach_at(aim) and gum.target == anchors, "Outside-art adhesion direction=%s" % direction)
		gum.update_aim(aim)
		check(gum.aim_point.is_equal_approx(center), "Aim reticle marks ring center")
		check(gum.endpoint().is_equal_approx(center), "Off-center hit snaps to ring center")
		check(is_equal_approx(gum.rest_length, gum.origin().distance_to(center)), "Initial natural length uses center")
		check(gum.path.points[-1].is_equal_approx(center) and gum.last_display[-1].is_equal_approx(center), "Physics and immediate drawing use center")
		gum.detach("TEST")
		player.position = center + tangent * 26 - direction * 100 + Vector2(0, 34)
		check(not gum.attach_at(center + tangent * 26), "Beyond adhesion margin misses direction=%s" % direction)
	# A diagonal approach into the invisible corner band also attaches.
	player.position = center + Vector2(100, 100) + Vector2(0, 34)
	check(gum.attach_at(center + Vector2(19, 19)) and gum.target == anchors, "Diagonal near-miss adhesion")
	check(gum.endpoint().is_equal_approx(center), "Diagonal hit snaps to center")
	gum.detach("TEST")
	player.position = center + Vector2(20, 140)
	gum.fire(Vector2.UP)
	for i in 20:
		await physics_frame
		gum.step(1.0 / 60.0)
		await process_frame
	check(gum.connected() and gum.target == anchors, "Moving shot missing artwork attaches within margin")
	check(gum.endpoint().is_equal_approx(center) and gum.tip.is_equal_approx(center), "Moving shot endpoint and tip finish at center")
	gum.detach("TEST")
	# A shot starting inside the inflated ring must attach, including at its center.
	for offset in [Vector2.ZERO, Vector2(20, 0), Vector2(-20, 0), Vector2(0, 20), Vector2(0, -20)]:
		for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2(1, -1).normalized()]:
			player.position = center + offset + Vector2(0, 34)
			gum.fire(direction)
			gum.step(1.0 / 60.0)
			check(gum.connected() and gum.target == anchors, "Overlapping ring shot attaches offset=%s direction=%s reason=%s" % [offset, direction, gum.release_reason])
			if gum.connected():
				check(gum.endpoint().is_equal_approx(center), "Overlapping shot snaps to ring center")
				check(is_zero_approx(gum.tension), "Overlap arrival has no immediate force")
				gum.step(1.0 / 60.0)
				check(gum.connected(), "Overlap connection survives next physics step")
			gum.detach("TEST")
	# The visible outer band remains attachable too.
	player.position = center + Vector2(13, 140)
	check(gum.attach_at(center + Vector2(13, 0)), "Enlarged ring outer band accepts adhesion")
	check(gum.target == anchors, "TileMap endpoint owner")
	gum.step(1.0 / 60.0)
	check(gum.connected() and gum.tension > 0, "Ring sustains contraction force")
	gum.detach("TEST")
	# Painting and erasing must affect rays and release an existing connection.
	var cell := Vector2i.ZERO
	player.position = center + Vector2(0, 140)
	check(gum.attach_at(center), "Attach before erase")
	anchors.erase_cell(cell)
	await settle()
	gum.step(1.0 / 60.0)
	check(not gum.connected(), "Erased tile releases endpoint")
	check(not gum.attach_at(center), "Erased tile cannot attach")
	anchors.set_cell(cell, 2, Vector2i.ZERO)
	await settle()
	gum.fire(Vector2.UP)
	for i in 20:
		await physics_frame
		gum.step(1.0 / 60.0)
		await process_frame
	check(gum.connected() and gum.target == anchors and gum.tension > 0, "Moving shot arrives and contracts on painted tile")
	gum.detach("TEST")
	player.position = center + Vector2(0, 134)
	var maximum_length: float = gum.settings.maximum_length
	gum.settings.maximum_length = 90
	check(not gum.attach_at(center), "Center beyond maximum length rejects even if inflated rim is in range")
	gum.settings.maximum_length = maximum_length
	# Per-cell RIDs disambiguate inflated hits beyond cell boundaries, also transformed.
	var second_cell := Vector2i(3, 0)
	anchors.set_cell(second_cell, 2, Vector2i.ZERO)
	anchors.rotation = 0.25
	anchors.scale = Vector2(1.2, 1.2)
	await settle()
	var second_center := anchors.to_global(anchors.map_to_local(second_cell))
	player.position = anchors.to_global(anchors.map_to_local(second_cell) + Vector2(20, 100)) + Vector2(0, 34)
	check(gum.attach_at(anchors.to_global(anchors.map_to_local(second_cell) + Vector2(20, 0))), "Transformed second ring accepts off-cell hit")
	check(gum.endpoint().is_equal_approx(second_center), "Off-cell hit selects correct transformed ring center")
	anchors.position += Vector2(50, 20)
	check(gum.endpoint().is_equal_approx(anchors.to_global(anchors.map_to_local(second_cell))), "Endpoint follows local tile center")
	anchors.collision_enabled = false
	check(not gum.connected(), "Disabled TileMap releases endpoint")
	print("Gum anchor verification: ", "PASS" if failures == 0 else "FAIL", " (", failures, ")")
	quit(0 if failures == 0 else 1)

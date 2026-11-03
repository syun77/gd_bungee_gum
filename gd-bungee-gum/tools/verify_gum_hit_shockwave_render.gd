extends SceneTree
## Run without --headless: requires an actual Compatibility renderer.
class EndpointFixture extends Node2D:
	func endpoint() -> Vector2:
		return Vector2(320, 240)

func _initialize():
	call_deferred("run")
func run():
	root.size = Vector2i(640, 480)
	var host = Node2D.new()
	root.add_child(host)
	for y in range(24):
		for x in range(32):
			var tile = Polygon2D.new()
			tile.polygon = PackedVector2Array([Vector2(x*20,y*20),Vector2(x*20+20,y*20),Vector2(x*20+20,y*20+20),Vector2(x*20,y*20+20)])
			tile.color = Color(0.18,0.4,0.44) if (x+y)%2==0 else Color(0.9,0.84,0.68)
			host.add_child(tile)
	var effect = load("res://scripts/gum_hit_shockwave.gd").new()
	host.add_child(effect)
	effect.settings = load("res://resources/game_settings.tres")
	effect.set_process(false)
	var gum = EndpointFixture.new()
	host.add_child(gum)
	effect.gum = gum
	await process_frame
	await RenderingServer.frame_post_draw
	var before = root.get_texture().get_image()
	before.save_png("/tmp/shockwave-before.png")
	effect._start(Vector2.UP,false)
	effect._process(0.3)
	await process_frame
	await RenderingServer.frame_post_draw
	var after = root.get_texture().get_image()
	after.save_png("/tmp/shockwave-after.png")
	var changed := 0
	for y in range(after.get_height()):
		for x in range(after.get_width()):
			if before.get_pixel(x, y) != after.get_pixel(x, y):
				changed += 1
	var passed := changed > 100
	print("Shockwave rendered pixel verification: ", "PASS" if passed else "FAIL", " (", changed, " changed pixels)")
	quit(0 if passed else 1)

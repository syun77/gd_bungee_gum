extends Node2D
## World-space frozen artwork, advanced by the Player's fixed-step owner.
const MAX_IMAGES := 8
var images: Array[Dictionary] = []
var cooldown := 0.0

func step(delta: float, source: AnimatedSprite2D, speed: float, settings) -> void:
	for index in range(images.size() - 1, -1, -1):
		var image := images[index]
		image.age += delta
		if image.age >= image.lifetime:
			image.sprite.free()
			images.remove_at(index)
		else:
			image.sprite.modulate.a = image.opacity * pow(1.0 - image.age / image.lifetime, 2.0)
	if not settings.afterimage_enabled or settings.afterimage_lifetime <= 0.0:
		clear()
		return
	if speed < settings.afterimage_minimum_speed or not source.is_visible_in_tree():
		cooldown = 0.0
		return
	cooldown = maxf(0.0, cooldown - delta)
	if cooldown > 0.0:
		return
	cooldown = maxf(settings.afterimage_interval, 0.001)
	if images.size() == MAX_IMAGES:
		images.pop_front().sprite.free()
	var ghost := Sprite2D.new()
	ghost.texture = source.sprite_frames.get_frame_texture(source.animation, source.frame)
	ghost.flip_h = source.flip_h
	ghost.flip_v = source.flip_v
	ghost.centered = source.centered
	ghost.offset = source.offset
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.show_behind_parent = true
	ghost.top_level = true
	add_child(ghost)
	ghost.global_transform = source.global_transform
	ghost.modulate = settings.afterimage_color
	images.append({"sprite": ghost, "age": 0.0, "lifetime": settings.afterimage_lifetime,
		"opacity": settings.afterimage_color.a})

func clear() -> void:
	for image in images:
		image.sprite.free()
	images.clear()
	cooldown = 0.0

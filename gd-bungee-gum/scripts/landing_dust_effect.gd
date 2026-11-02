extends Sprite2D
## Short presentation-only burst at the contacted floor, independent of player motion.
const NORMAL = preload("res://assets/effects/landing_dust_normal.png")
const HEAVY = preload("res://assets/effects/landing_dust_heavy.png")
const FPS := 30.0
const VISIBLE_FRAMES := 9
const Settings = preload("res://scripts/game_settings.gd")
var settings: Settings
var elapsed := 0.0
var follows_surface := false
var surface: RigidBody2D
var local_point := Vector2.ZERO
var local_normal := Vector2.UP

func bind(player: CharacterBody2D) -> void:
	settings = player.settings
	player.landed.connect(_start)

func _start(point: Vector2, normal: Vector2, impact_speed: float, body: Node2D) -> void:
	if impact_speed < settings.landing_dust_minimum_speed:
		return
	texture = HEAVY if impact_speed >= maxf(settings.landing_dust_heavy_speed, settings.landing_dust_minimum_speed) else NORMAL
	global_position = point
	global_rotation = Vector2.UP.angle_to(normal)
	surface = body as RigidBody2D
	follows_surface = surface != null
	if follows_surface:
		local_point = surface.to_local(point)
		local_normal = surface.global_transform.basis_xform_inv(normal)
	elapsed = 0.0
	frame = 0
	visible = true

func stop() -> void:
	visible = false
	surface = null
	follows_surface = false

func _process(delta: float) -> void:
	if not visible:
		return
	elapsed += delta
	if elapsed >= VISIBLE_FRAMES / FPS:
		stop()
		return
	frame = int(elapsed * FPS)
	if follows_surface:
		if not is_instance_valid(surface):
			stop()
			return
		global_position = surface.to_global(local_point)
		global_rotation = Vector2.UP.angle_to(surface.global_transform.basis_xform(local_normal).normalized())

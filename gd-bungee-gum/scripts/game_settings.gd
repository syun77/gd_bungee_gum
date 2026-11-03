extends Resource
## Shared tuning resource. Edit resources/game_settings.tres in the Inspector.
@export_group("Player Movement")
## Maximum input-driven speed (px/s).
@export_range(0.0, 2000.0) var run_speed := 220.0
## Input acceleration and braking (px/s²).
@export_range(0.0, 10000.0) var ground_acceleration := 1600.0
@export_range(0.0, 10000.0) var air_acceleration := 350.0
## Ground tangent deceleration of external velocity (px/s²).
@export_range(0.0, 5000.0) var ground_friction := 900.0
@export_range(0.0, 5000.0) var gravity := 1100.0
## Contact kick-off impulse expressed as speed (px/s).
@export_range(0.0, 2000.0) var kick_speed := 400.0
## Floor-departure kick grace (seconds); zero disables it.
@export_range(0.0, 0.3, 0.01) var coyote_time := 0.2
## Pre-landing jump input grace (seconds); zero disables it.
@export_range(0.0, 0.3, 0.01) var jump_buffer_time := 0.12
@export_range(0.01, 1000.0) var player_mass := 1.0

@export_group("Ladder")
## Vertical climbing speed (px/s); zero disables grabbing.
@export_range(0.0, 600.0) var ladder_speed := 120.0

@export_group("Food Collection")
## Food pull speed toward the frozen player's hand (px/s).
@export_range(1.0, 4000.0) var food_reel_speed := 600.0

@export_group("Player Squash and Stretch")
## Visual-only horizontal (X) and vertical (Y) multipliers on upward launch.
@export var jump_stretch := Vector2(0.84, 1.41)
## Recovery time in seconds; zero disables jump deformation.
@export_range(0.0, 1.0, 0.01) var jump_stretch_duration := 0.31
## Visual-only horizontal (X) and vertical (Y) multipliers on landing.
@export var landing_squash := Vector2(1.44, 0.82)
## Recovery time in seconds; zero disables landing deformation.
@export_range(0.0, 1.0, 0.01) var landing_squash_duration := 0.31

@export_group("Player Afterimages")
@export var afterimage_enabled := true
## Actual world movement speed (px/s), including vertical motion.
@export_range(0.0, 3000.0) var afterimage_minimum_speed := 350.0
@export_range(0.01, 0.5, 0.01) var afterimage_interval := 0.04
## Seconds until a frozen pose disappears; zero disables emission.
@export_range(0.0, 1.0, 0.01) var afterimage_lifetime := 0.20
## Solid silhouette RGB and initial opacity; original texture contributes alpha only.
@export var afterimage_color := Color(1.0, 0.72, 0.85, 0.32)

@export_group("Landing Dust")
## Minimum floor-normal relative impact speed for visible dust (px/s).
@export_range(0.0, 2000.0) var landing_dust_minimum_speed := 80.0
## Floor-normal relative impact speed selecting the heavy burst (px/s).
@export_range(0.0, 2000.0) var landing_dust_heavy_speed := 450.0

@export_group("Player Contact")
## Repulsion skin around the unchanged player capsule; floor support uses real collisions (px).
@export_range(0.0, 2.0) var contact_clearance := 0.75
## Fraction of closing speed returned on non-support impacts faster than 30 px/s.
@export_range(0.0, 1.0) var contact_restitution := 0.1
## Fraction of non-support rigid penetration corrected per physics tick.
@export_range(0.0, 1.0) var contact_penetration_response := 0.8
## Maximum penetration-driven separation speed (px/s).
@export_range(0.0, 1000.0) var contact_separation_speed := 120.0

@export_group("Gum Physics")
@export_range(0.0, 200.0) var stiffness := 35.0
@export_range(0.0, 100.0) var damping := 9.0
@export_range(1.0, 1000.0) var contraction_speed := 180.0
@export_range(1.0, 900.0) var minimum_length := 4.0
## Maximum straight-line firing distance (px), independent of connected path length.
@export_range(1.0, 3000.0) var attachment_range := 160.0
## Maximum connected path length, including wrapping (px).
@export_range(1.0, 3000.0) var maximum_length := 400.0
@export_range(1.0, 10000.0) var maximum_tension := 2800.0
## Manual relaxed-mode length changes (px/s).
@export_range(1.0, 1000.0) var manual_extension_speed := 180.0
@export_range(1.0, 1000.0) var manual_shortening_speed := 90.0
## Reserve between manual natural-length cap and path break limit (px).
@export_range(1.0, 500.0) var manual_length_margin := 240.0

@export_group("Gum Flight")
@export_range(1.0, 10000.0) var gum_shot_speed := 1200.0
@export_range(1.0, 10000.0) var gum_return_speed := 3200.0
@export_range(0.01, 2.0) var gum_return_max_duration := 0.25

@export_group("Gum Wrapping")
@export_range(0.25, 4.0) var wrap_clearance := 1.0
@export_range(1.0, 8.0) var wrap_release_margin := 2.0
@export_range(1, 10) var wrap_release_ticks := 2
@export_range(1, 64) var wrap_max_pivots := 16
@export_range(1, 128) var wrap_max_repairs := 32

@export_group("Aim Guide")
## Unavailable-target alpha multiplier; valid targets use their color alpha directly.
@export_range(0.0, 1.0) var aim_guide_opacity := 0.3
## Target available / unavailable. Alpha controls both guide and reticle opacity.
@export var aim_valid_color := Color(0.45, 1.0, 0.75, 0.9)
@export var aim_invalid_color := Color(1.0, 0.7, 0.6, 0.9)
@export_range(1.0, 10.0) var aim_line_width := 2.0
@export_range(1.0, 40.0) var aim_dash_length := 6.0
@export_range(1.0, 40.0) var aim_reticle_radius := 7.0
@export_range(1.0, 10.0) var aim_reticle_width := 1.5

@export_group("Gum Appearance")
## Relaxed manual-length mode, independent of tension.
@export var gum_loosen_color := Color("#B8A6AD")
@export var gum_slack_color := Color("#FF8DD6")
@export var gum_taut_color := Color("#FF62BD")
@export_range(1.0, 10.0) var gum_line_width := 4.0
## Additional width at maximum tension (px).
@export_range(0.0, 10.0) var gum_tension_width := 4.0

## Additive bloom halo radius beyond the gum edge (px); zero disables the halo.
@export_range(0.0, 24.0) var gum_glow_radius := 18.0
@export_range(0.0, 1.0) var gum_glow_opacity := 0.18
## White mixed into the narrow luminous core; zero keeps the base color.
@export_range(0.0, 1.0) var gum_core_brightness := 0.12

@export_group("Gum Shot Particles")
@export var gum_shot_particles_enabled := true
## Mean world-space distance between particles; randomized by +/-20 percent.
@export_range(2.0, 32.0) var gum_particle_spacing := 10.0
@export_range(0.02, 0.5) var gum_particle_lifetime := 0.5
@export_range(0.0, 16.0) var gum_particle_spread := 16.0
@export_range(0.0, 1.0) var gum_particle_opacity := 1.0

@export_group("Gum Hit Particles")
@export var gum_hit_particles_enabled := true
@export_range(4, 16) var gum_hit_particle_count := 16
## Outer radius of the expanding particle ring (world px).
@export_range(6.0, 40.0) var gum_hit_particle_radius := 20.0
@export_range(0.08, 0.5) var gum_hit_particle_lifetime := 0.5
@export_range(0.0, 1.0) var gum_hit_particle_opacity := 1.0
## Brief faint arcs supplement the particle ring when enabled.
@export var gum_hit_arcs_enabled := false

@export_group("Gum Hit Shockwave")
@export var gum_hit_shockwave_enabled := true
## World-space outer radius; refraction strength is measured in screen pixels.
@export_range(8.0, 160.0) var gum_hit_shockwave_radius := 56.0
@export_range(0.0, 1.0) var gum_hit_shockwave_duration := 0.32
@export_range(0.0, 16.0) var gum_hit_shockwave_strength := 4.0
@export_range(0.0, 1.0) var gum_hit_shockwave_opacity := 0.3

@export_group("Camera Zoom")
## Camera2D scale: larger values show a closer view.
@export_range(0.1, 4.0) var camera_normal_zoom := 1.5
@export_range(0.1, 4.0) var camera_long_gum_zoom := 1.0
## Total wrapped path lengths (px) at which distance zoom starts / reaches its limit.
@export_range(0.0, 3000.0) var camera_gum_zoom_start := 200.0
@export_range(0.0, 3000.0) var camera_gum_zoom_end := 800.0
## Exponential response rate (1/s); zero snaps immediately.
@export_range(0.0, 30.0) var camera_zoom_response := 5.0

@export_group("Stage Rules")
## Restart below this world-space Y coordinate (px).
@export var restart_y := 900.0

@export_group("Diagnostics")
## Log rigid contacts or stalled penetration, movement, nearby bodies and gum force.
@export var pinning_diagnostics := false
## Log gum releases with endpoint physics, obstruction details and eight preceding steps.
@export var gum_diagnostics := false
## Log contact kick-off requests, rejection reasons and rearming.
@export var jump_diagnostics := false
## Log unexpected vertical control velocity and subsequent floor transitions.
@export var landing_diagnostics := false

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
@export_range(0.01, 1000.0) var player_mass := 1.0

@export_group("Gum Physics")
@export_range(0.0, 200.0) var stiffness := 35.0
@export_range(0.0, 100.0) var damping := 9.0
@export_range(1.0, 1000.0) var contraction_speed := 180.0
@export_range(1.0, 900.0) var minimum_length := 36.0
@export_range(1.0, 3000.0) var maximum_length := 400.0
@export_range(1.0, 10000.0) var maximum_tension := 2800.0
@export_range(0.0, 200.0) var loosen_margin := 32.0

@export_group("Gum Wrapping")
@export_range(0.25, 4.0) var wrap_clearance := 1.0
@export_range(1.0, 8.0) var wrap_release_margin := 2.0
@export_range(1, 10) var wrap_release_ticks := 2
@export_range(1, 64) var wrap_max_pivots := 16
@export_range(1, 128) var wrap_max_repairs := 32

@export_group("Aim Guide")
## Target available / unavailable. Alpha controls both guide and reticle opacity.
@export var aim_valid_color := Color(0.45, 1.0, 0.75, 0.9)
@export var aim_invalid_color := Color(1.0, 0.7, 0.6, 0.9)
@export_range(1.0, 10.0) var aim_line_width := 2.0
@export_range(1.0, 40.0) var aim_dash_length := 6.0
@export_range(1.0, 40.0) var aim_reticle_radius := 7.0
@export_range(1.0, 10.0) var aim_reticle_width := 1.5

@export_group("Gum Appearance")
## Fixed-length loosen mode, independent of tension.
@export var gum_loosen_color := Color("#B8A6AD")
@export var gum_slack_color := Color(1.0, 0.52, 0.8, 1.0)
@export var gum_taut_color := Color(1.0, 0.2, 0.28, 1.0)
@export_range(1.0, 10.0) var gum_line_width := 2.0
## Additional width at maximum tension (px).
@export_range(0.0, 10.0) var gum_tension_width := 4.0

@export_group("Camera Zoom")
## Camera2D scale: larger values show a closer view.
@export_range(0.1, 4.0) var camera_normal_zoom := 1.5
@export_range(0.1, 4.0) var camera_hold_zoom := 1.2
@export_range(0.1, 4.0) var camera_long_gum_zoom := 1.0
## Continuous X hold time before requesting the wider view (seconds).
@export_range(0.0, 2.0) var camera_hold_delay := 0.0
## Total wrapped path lengths (px) at which distance zoom starts / reaches its limit.
@export_range(0.0, 3000.0) var camera_gum_zoom_start := 200.0
@export_range(0.0, 3000.0) var camera_gum_zoom_end := 800.0
## Exponential response rate (1/s); zero snaps immediately.
@export_range(0.0, 30.0) var camera_zoom_response := 5.0

@export_group("Stage Rules")
## Restart below this world-space Y coordinate (px).
@export var restart_y := 900.0

@export_group("Diagnostics")
## Log contact kick-off requests, rejection reasons and rearming.
@export var jump_diagnostics := true
## Log unexpected vertical control velocity and subsequent floor transitions.
@export var landing_diagnostics := true

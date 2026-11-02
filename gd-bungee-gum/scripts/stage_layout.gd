extends RefCounted
## Authored 32px geometry and placements for the current saved-tuning prototype.
const TILE := 32
const SIZE := Vector2i(160, 24)
const TERRAIN := [
	Rect2i(0, 2, 2, 22), Rect2i(2, 2, 156, 2), Rect2i(158, 2, 2, 22),
	# Contact: 128px lift onto a wide exit; low shelf teaches the 64px kick.
	Rect2i(2, 20, 18, 4), Rect2i(20, 16, 6, 8), Rect2i(12, 11, 8, 1),
	# Swing: upper shortcut, broad recovery basin and 128+64px recovery climb.
	Rect2i(26, 22, 22, 2), Rect2i(48, 16, 6, 8),
	Rect2i(28, 10, 10, 1), Rect2i(40, 13, 8, 1),
	# Light cargo: open box workspace below the landing shelves.
	Rect2i(54, 20, 18, 4), Rect2i(72, 14, 8, 10), Rect2i(64, 11, 8, 1),
	# Heavy anchor: elevated box ledge, optional high route and safe lower basin.
	Rect2i(80, 22, 20, 2), Rect2i(100, 16, 6, 8),
	Rect2i(80, 8, 10, 2), Rect2i(84, 14, 4, 1), Rect2i(92, 13, 8, 1),
	# Redirect workspace: 64px cover, open sight lines and a 128px exit lift.
	Rect2i(106, 20, 18, 4), Rect2i(124, 16, 8, 8),
	Rect2i(110, 18, 2, 2), Rect2i(114, 18, 2, 2), Rect2i(116, 11, 8, 1),
	# Exit: two reachable beams, separated horizontally to avoid a blocked upper shot.
	Rect2i(132, 22, 18, 2), Rect2i(150, 12, 8, 12),
	Rect2i(140, 13, 6, 1), Rect2i(146, 7, 4, 1),
]
const ONE_WAY_FLOORS := [
	Rect2i(8, 18, 2, 1), Rect2i(14, 16, 6, 1),
	Rect2i(30, 16, 6, 1), Rect2i(36, 18, 4, 1),
	Rect2i(42, 18, 6, 1), Rect2i(44, 16, 4, 1),
	Rect2i(66, 16, 6, 1), Rect2i(68, 14, 4, 1),
	Rect2i(88, 16, 4, 1), Rect2i(94, 18, 6, 1), Rect2i(96, 16, 4, 1),
	Rect2i(118, 16, 6, 1),
	Rect2i(142, 18, 8, 1), Rect2i(144, 16, 6, 1), Rect2i(146, 12, 4, 1),
]
const SECTION_NAMES := ["01 / CONTACT", "02 / SWING", "03 / LIGHT CARGO", "04 / HEAVY ANCHOR", "05 / REDIRECT", "06 / EXIT"]
const SECTION_STARTS := [Vector2(160, 640), Vector2(864, 512), Vector2(1792, 640), Vector2(2624, 448), Vector2(3456, 640), Vector2(4288, 704)]
const MARKERS := {
	"PlayerSpawn": Vector2(160, 620),
	"LightBoxSpawn": Vector2(1952, 620),
	"HeavyBoxSpawn": Vector2(2752, 428),
	"ProjectileEmitter": Vector2(3456, 600),
	"ProjectileTarget": Vector2(4160, 472),
	"Exit": Vector2(4944, 384),
}
# Baseline lower route: each point is a real floor and an unobstructed upward shot.
# The 222px hand-to-beam distance leaves 18px inside attachment_range=240.
const LIFTS := [
	{"start": Vector2(576, 640), "landing_y": 512.0},
	{"start": Vector2(1472, 704), "landing_y": 576.0, "kick_y": 512.0},
	{"start": Vector2(2240, 640), "landing_y": 512.0, "kick_y": 448.0},
	{"start": Vector2(3136, 704), "landing_y": 576.0, "kick_y": 512.0},
	{"start": Vector2(3904, 640), "landing_y": 512.0},
	{"start": Vector2(4608, 704), "landing_y": 576.0, "kick_y": 512.0},
	{"start": Vector2(4736, 512), "landing_y": 384.0},
]

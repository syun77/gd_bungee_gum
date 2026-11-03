extends RefCounted
## Authored 32px geometry and placements for the current saved-tuning prototype.
# Two-cell floor strips leave room for a contact kick; upper strips guard optional shortcuts.
const SPIKES: Array[Vector2i] = [
	Vector2i(10, 19), Vector2i(11, 19),
	Vector2i(34, 21), Vector2i(35, 21),
	Vector2i(64, 19), Vector2i(65, 19),
	Vector2i(87, 21), Vector2i(88, 21),
	Vector2i(119, 19), Vector2i(120, 19),
	Vector2i(137, 21), Vector2i(138, 21),
	Vector2i(28, 9), Vector2i(29, 9),
	Vector2i(64, 10), Vector2i(65, 10),
	Vector2i(80, 7), Vector2i(81, 7),
	Vector2i(116, 10), Vector2i(117, 10),
]
const LADDERS := [Vector3(464, 640, 128)] # Bottom x/y, height; optional first shelf.
const CHECKPOINTS := [Vector2(896, 704), Vector2(1824, 640), Vector2(2656, 704), Vector2(3488, 640), Vector2(4320, 704)]
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
# Gum-only hit area intentionally extends 9px beyond the 30px artwork.
const GUM_ANCHOR_POLYGON := [
	Vector2(-16, -24), Vector2(16, -24), Vector2(24, -16), Vector2(24, 16),
	Vector2(16, 24), Vector2(-16, 24), Vector2(-24, 16), Vector2(-24, -16),
]
# Authored pass-through attachment points, matching the saved GumAnchors layer.
const GUM_ANCHORS := [
	Vector2i(5, 12), Vector2i(7, 9), Vector2i(10, 7), Vector2i(22, 10),
	Vector2i(25, 8), Vector2i(38, 10), Vector2i(43, 8), Vector2i(60, 14),
	Vector2i(62, 8), Vector2i(90, 11), Vector2i(120, 14), Vector2i(138, 16),
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

# Six pickups per section: lower route, step/lift landings and optional high shelf.
# Vector3i stores cell x/y and food scene ID from food_tileset.tres.
const FOODS := [
	Vector3i(7, 19, 5), Vector3i(9, 17, 8), Vector3i(16, 15, 9),
	Vector3i(18, 19, 6), Vector3i(23, 15, 4), Vector3i(16, 10, 3),
	Vector3i(29, 21, 7), Vector3i(33, 15, 6), Vector3i(38, 17, 8),
	Vector3i(45, 17, 9), Vector3i(51, 15, 0), Vector3i(33, 9, 3),
	Vector3i(57, 19, 1), Vector3i(63, 19, 5), Vector3i(68, 15, 10),
	Vector3i(70, 13, 8), Vector3i(75, 13, 2), Vector3i(68, 10, 4),
	Vector3i(82, 21, 6), Vector3i(86, 13, 1), Vector3i(90, 15, 7),
	Vector3i(96, 17, 9), Vector3i(103, 15, 2), Vector3i(85, 7, 3),
	Vector3i(108, 19, 8), Vector3i(110, 17, 9), Vector3i(114, 17, 0),
	Vector3i(120, 15, 10), Vector3i(127, 15, 4), Vector3i(120, 10, 1),
	Vector3i(135, 21, 7), Vector3i(140, 21, 5), Vector3i(144, 17, 10),
	Vector3i(147, 15, 0), Vector3i(148, 11, 2), Vector3i(154, 11, 3),
]

# Decoration center cell x/y and row-major ID in the dedicated 4x4 atlas.
# Each stamp draws 96x96px on the 32px placement grid; no physics.
const BACKGROUND_DECOR := [
	Vector3i(4, 18, 0), Vector3i(18, 18, 1), Vector3i(16, 5, 4),
	Vector3i(22, 5, 5), Vector3i(7, 13, 8), Vector3i(15, 14, 12), Vector3i(23, 13, 6),
	Vector3i(29, 20, 2), Vector3i(44, 20, 7), Vector3i(42, 5, 5),
	Vector3i(46, 5, 4), Vector3i(32, 13, 9), Vector3i(42, 9, 13), Vector3i(39, 7, 3),
	Vector3i(56, 18, 1), Vector3i(70, 18, 0), Vector3i(68, 5, 4),
	Vector3i(74, 5, 5), Vector3i(59, 11, 10), Vector3i(67, 8, 14), Vector3i(75, 11, 6),
	Vector3i(82, 20, 2), Vector3i(98, 20, 7), Vector3i(94, 5, 5),
	Vector3i(102, 5, 4), Vector3i(89, 17, 11), Vector3i(95, 9, 15), Vector3i(92, 6, 3),
	Vector3i(108, 18, 0), Vector3i(121, 18, 1), Vector3i(120, 5, 4),
	Vector3i(126, 5, 5), Vector3i(111, 12, 8), Vector3i(119, 8, 13), Vector3i(128, 13, 6),
	Vector3i(134, 20, 2), Vector3i(148, 20, 7), Vector3i(146, 5, 5),
	Vector3i(154, 5, 4), Vector3i(136, 13, 9), Vector3i(143, 9, 12), Vector3i(153, 9, 15),
]

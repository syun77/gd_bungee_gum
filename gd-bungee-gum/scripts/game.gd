extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	player.global_position = $TheaterStage/PlacementMarkers/PlayerSpawn.global_position
	camera.position = player.position

func _physics_process(_delta: float) -> void:
	# 親Gameは子Playerより先に物理更新されるため、直前ティックの位置を追う。
	# マップ端ではCamera2Dのlimitで追従が止まり、プレイヤーが画面内を移動する。
	camera.position = player.position
	if Input.is_action_just_pressed("restart") or player.position.y > 900.0:
		get_tree().reload_current_scene()

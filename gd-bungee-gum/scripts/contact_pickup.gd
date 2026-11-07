extends Area2D

const ScorePopup = preload("res://scripts/score_popup.gd")

@export var points := 30

signal collected

var is_collected := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect()

func collect() -> void:
	if is_collected:
		return
	is_collected = true
	ScorePopup.spawn(self, points)
	hide()
	set_process(false)
	get_node("/root/SoundEffects").play(&"item")
	collected.emit()
	queue_free()

extends Area2D
## Scene tile collectible; gum can reel it to the player's hand.
signal collected(food_id: StringName)
@export var food_id: StringName
var is_collected := false
var being_pulled := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func collect() -> void:
	if is_collected:
		return
	is_collected = true
	hide()
	collected.emit(food_id)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if not being_pulled and body.is_in_group("player"):
		collect()

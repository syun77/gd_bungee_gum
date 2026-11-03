extends Area2D
## Scene tile collectible; gum can reel it to the player's hand.
const CollectionEffect = preload("res://scripts/food_collect_effect.gd")
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
	SoundEffects.play(&"item")
	var effect := CollectionEffect.new()
	# Keep residue outside the scene tile so deleting the food does not delete it.
	var host := get_parent()
	if host is TileMapLayer:
		host = host.get_parent()
	host.add_child(effect)
	effect.global_position = global_position
	hide()
	collected.emit(food_id)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if not being_pulled and body.is_in_group("player"):
		collect()

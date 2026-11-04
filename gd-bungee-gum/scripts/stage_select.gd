extends Control
## Select a course without changing the physics settings.
const Catalog = preload("res://scripts/stage_catalog.gd")
const INK := Color("344e50")
var starting := false
var start_button: Button
var stage_buttons: Array[Button] = []

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("f5eedc")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 1120
	content.add_theme_constant_override("separation", 20)
	center.add_child(content)
	_label(content, "BUNGEE GUM", 28, Color("c86670"))
	_label(content, "ステージ選択", 48)
	_label(content, "くっつけて、引っぱって、飛びこもう。", 24)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 20)
	content.add_child(cards)
	for index in Catalog.STAGES.size():
		_add_card(cards, index)
	start_button = stage_buttons[0]
	_label(content, "クリック / 矢印で選択・Enter / パッドで選択・決定", 20)
	start_button.grab_focus()

func _add_card(parent: HBoxContainer, index: int) -> void:
	var course: Dictionary = Catalog.STAGES[index]
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("e0e9de")
	panel.border_color = Color("84aaa0")
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(16)
	panel.content_margin_left = 20
	panel.content_margin_right = 20
	panel.content_margin_top = 28
	panel.content_margin_bottom = 28
	card.add_theme_stylebox_override("panel", panel)
	parent.add_child(card)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 24)
	card.add_child(details)
	_label(details, "STAGE %02d" % (index + 1), 24, Color("a44e5d"))
	_label(details, course.title, 28)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/foods/%s.png" % course.food)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(96, 96)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	details.add_child(icon)
	_label(details, course.description, 20)
	var button := Button.new()
	button.text = "はじめる"
	button.custom_minimum_size.y = 68
	for color_name in ["font_color", "font_hover_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, INK)
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("f2a39c") if state == "normal" else Color("ffd0b8")
		style.set_corner_radius_all(8)
		button.add_theme_stylebox_override(state, style)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = INK
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(8)
	button.add_theme_stylebox_override("focus", focus)
	details.add_child(button)
	button.pressed.connect(start_stage.bind(index))
	stage_buttons.append(button)

func _label(parent: Node, text: String, size: int, color := INK) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func start_stage(index := 0) -> void:
	if starting:
		return
	starting = true
	if get_tree().has_meta(&"checkpoint_respawn"):
		get_tree().remove_meta(&"checkpoint_respawn")
	var error := get_tree().change_scene_to_file(Catalog.STAGES[index].scene)
	if error != OK:
		starting = false
		push_error("Cannot open restaurant stage: %s" % error_string(error))

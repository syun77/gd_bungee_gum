extends Control

const INK := Color("344e50")

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("f5eedc")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	center.add_child(content)
	_add_label(content, "BUNGEE GUM", 28, Color("a44e5d"))
	_add_label(content, "モード選択", 48)

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 24)
	content.add_child(cards)
	var stage_button := _add_card(cards, "STAGE", "ステージモード",
		"コースを選んでゴールを目指そう", Color("dcebe1"), "ステージを選ぶ")
	var time_button := _add_card(cards, "TIME ATTACK", "タイムアタックモード",
		"レストラン・スプリント", Color("f6dfd4"), "挑戦する")

	stage_button.pressed.connect(_open_scene.bind("stage_select"))
	time_button.pressed.connect(_open_scene.bind("game_time_attack"))
	var replay := Button.new()
	replay.text = "リプレイ再生"
	replay.custom_minimum_size.y = 64
	replay.disabled = not ReplayStore.available()
	content.add_child(replay)
	replay.pressed.connect(func(): ReplayStore.play("res://scenes/mode_select.tscn"))
	stage_button.grab_focus()

func _add_card(parent: HBoxContainer, tag: String, title: String, description: String,
		color: Color, action: String) -> Button:
	var card := PanelContainer.new()
	card.custom_minimum_size.x = 460
	var panel := StyleBoxFlat.new()
	panel.bg_color = color
	panel.border_color = Color("84aaa0")
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(16)
	panel.content_margin_left = 24
	panel.content_margin_right = 24
	panel.content_margin_top = 30
	panel.content_margin_bottom = 30
	card.add_theme_stylebox_override("panel", panel)
	parent.add_child(card)

	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 18)
	card.add_child(details)
	_add_label(details, tag, 24, Color("a44e5d"))
	_add_label(details, title, 30)
	_add_label(details, description, 22)
	var button := Button.new()
	button.text = action
	button.custom_minimum_size.y = 64
	details.add_child(button)
	return button

func _add_label(parent: Control, caption: String, font_size: int, color := INK) -> void:
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _open_scene(scene: String) -> void:
	var error := get_tree().change_scene_to_file("res://scenes/%s.tscn" % scene)
	if error != OK:
		push_error("Cannot open %s: %s" % [scene, error_string(error)])

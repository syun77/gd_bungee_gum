extends CanvasLayer
## Pause the world while keeping menu input and focus navigation alive.
signal retry_requested
signal selection_requested
signal resumed
var is_open := false
var buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	hide()
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.12, 0.12, 0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 440
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f5eedc")
	style.border_color = Color("84aaa0")
	style.set_border_width_all(4)
	style.set_corner_radius_all(16)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)
	var title := Label.new()
	title.text = "メニュー"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("344e50"))
	column.add_child(title)
	for text in ["リトライ", "ステージ選択に戻る", "キャンセル"]:
		var button := Button.new()
		button.text = text
		button.custom_minimum_size.y = 64
		column.add_child(button)
		buttons.append(button)
	buttons[0].pressed.connect(func(): retry_requested.emit())
	buttons[1].pressed.connect(func(): selection_requested.emit())
	buttons[2].pressed.connect(close)
	_update_focus_neighbors()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if is_open:
			close()
		else:
			open()

func open() -> void:
	if is_open:
		return
	is_open = true
	show()
	get_tree().paused = true
	buttons[0].grab_focus()

func close() -> void:
	if not is_open:
		return
	is_open = false
	hide()
	get_tree().paused = false
	for button in buttons:
		button.release_focus()
	resumed.emit()

func _exit_tree() -> void:
	if is_open:
		get_tree().paused = false

func add_replay_action(action: Callable) -> void:
	var button := Button.new()
	button.text = "リプレイ再生"
	button.custom_minimum_size.y = 64
	buttons[0].get_parent().add_child(button)
	button.pressed.connect(action)
	buttons.append(button)
	# Availability changes when a run reaches the goal.
	visibility_changed.connect(func(): button.disabled = not ReplayStore.available())
	button.disabled = not ReplayStore.available()
	_update_focus_neighbors()

func _update_focus_neighbors() -> void:
	for index in buttons.size():
		buttons[index].focus_neighbor_top = buttons[index].get_path_to(buttons[posmod(index - 1, buttons.size())])
		buttons[index].focus_neighbor_bottom = buttons[index].get_path_to(buttons[(index + 1) % buttons.size()])

@tool
extends EditorPlugin

const Exchange = preload("stage_exchange.gd")
const COPY := "MapEdit: Copy gameplay placements"
const PASTE := "MapEdit: Paste gameplay placements"

var confirm: ConfirmationDialog
var message: AcceptDialog

func _enter_tree() -> void:
	add_tool_menu_item(COPY, copy_stage)
	add_tool_menu_item(PASTE, paste_stage)
	confirm = ConfirmationDialog.new()
	message = AcceptDialog.new()
	add_child(confirm)
	add_child(message)

func _exit_tree() -> void:
	remove_tool_menu_item(COPY)
	remove_tool_menu_item(PASTE)
	confirm.queue_free()
	message.queue_free()

func copy_stage() -> void:
	var data := Exchange.snapshot(EditorInterface.get_edited_scene_root())
	if data.is_empty():
		show_message("Open time_attack.tscn or theater_stage.tscn directly.")
		return
	data["base"] = Exchange.token(data)
	DisplayServer.clipboard_set(JSON.stringify(data, "", true, true))
	show_message("Gameplay placements copied.")

func paste_stage() -> void:
	var stage := EditorInterface.get_edited_scene_root()
	var before := Exchange.snapshot(stage)
	var data: Variant = JSON.parse_string(DisplayServer.clipboard_get())
	var error := Exchange.validate(stage, before, data)
	if not error.is_empty():
		show_message(error)
		return
	var changes := Exchange.diff(before, data)
	if changes.old.is_empty() and changes.next.is_empty() and changes.markers.is_empty():
		show_message("No placement changes.")
		return
	var accept := func() -> void:
		if EditorInterface.get_edited_scene_root() != stage or Exchange.token(Exchange.snapshot(stage)) != data.base:
			show_message("The active stage changed. Copy the stage again.")
			return
		Exchange.commit(get_undo_redo(), stage, changes)
	# Remove any previously dismissed preview callback before connecting.
	for connection in confirm.confirmed.get_connections():
		confirm.confirmed.disconnect(connection.callable)
	confirm.confirmed.connect(accept, CONNECT_ONE_SHOT)
	confirm.dialog_text = "%d tile writes, %d tile removals/replacements, %d marker moves." % [
		changes.next.size(), changes.old.size(), changes.markers.size()]
	confirm.popup_centered()

func show_message(body: String) -> void:
	message.dialog_text = body
	message.popup_centered()

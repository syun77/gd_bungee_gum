@tool
extends EditorPlugin

const Exchange = preload("stage_exchange.gd")
const DirectPaste = preload("direct_paste.gd")
const COPY := "MapEdit: Copy gameplay placements"

var confirm: ConfirmationDialog
var message: AcceptDialog
var direct := DirectPaste.new()
var preview_trace := "-"
var preview_completion := Callable()

func _enter_tree() -> void:
	add_tool_menu_item(COPY, copy_stage)
	confirm = ConfirmationDialog.new()
	message = AcceptDialog.new()
	add_child(confirm)
	confirm.canceled.connect(cancel_preview)
	add_child(message)
	# The bridge belongs to the interactive editor; headless verification uses the paste logic directly.
	if DisplayServer.get_name() != "headless":
		var error := direct.start()
		if error != OK:
			push_warning("MapEdit direct paste could not listen on localhost: " + error_string(error))
		set_process(error == OK)

func _process(_delta: float) -> void:
	direct.poll(preview_paste)

func _exit_tree() -> void:
	direct.stop()
	remove_tool_menu_item(COPY)
	confirm.queue_free()
	message.queue_free()

func copy_stage() -> void:
	var stage := EditorInterface.get_edited_scene_root()
	var error := Exchange.snapshot_error(stage)
	if not error.is_empty():
		show_message(error)
		return
	var data := Exchange.snapshot(stage)
	if data.is_empty():
		show_message("ステージの配置データを取得できませんでした。")
		return
	data["base"] = Exchange.token(data)
	data["source"] = {"cells": data.cells, "markers": data.markers}
	DisplayServer.clipboard_set(JSON.stringify(data, "", true, true))
	show_message("Gameplay placements copied.")

func preview_paste(json: String, completion: Callable) -> Dictionary:
	var trace := json.sha256_text().left(12)
	if confirm.visible:
		DirectPaste.log_event("direct rejected: preview already open", trace)
		return {"status": "error", "message": "Finish the existing Godot paste confirmation first."}
	var stage := EditorInterface.get_edited_scene_root()
	DirectPaste.log_event("direct validation: active stage=%s" % (stage.scene_file_path if stage else "<none>"), trace)
	var before := Exchange.snapshot(stage)
	var data: Variant = JSON.parse_string(json)
	var error := Exchange.validate(stage, before, data)
	var merged_changes := false
	var additions_only := false
	if error.is_empty() or error == Exchange.STALE:
		var merged := Exchange.merge_stale(stage, before, data)
		if merged.has("data"):
			data = merged.data
			merged_changes = error == Exchange.STALE
			error = Exchange.validate(stage, before, data)
			DirectPaste.log_event("stale revision: merged independent edits", trace)
		elif merged.has("error"):
			error = merged.error
	if error == Exchange.STALE:
		var candidate := Exchange.checkpoint_additions_only(before, data)
		if not candidate.is_empty():
			data = candidate
			additions_only = true
			DirectPaste.log_event("stale revision: checkpoint-only preview", trace)
			error = Exchange.validate(stage, before, data)
	if not error.is_empty():
		DirectPaste.log_event("validation rejected: " + error, trace)
		return {"status": "error", "message": error}
	var changes := Exchange.diff(before, data)
	if changes.old.is_empty() and changes.next.is_empty() and changes.markers.is_empty() \
			and changes.checkpoints_added.is_empty() and changes.checkpoints_removed.is_empty():
		DirectPaste.log_event("validation passed: no changes", trace)
		return {"status": "unchanged", "message": "No placement changes."}
	var expected_base: String = data.base
	var accept := func() -> void:
		if EditorInterface.get_edited_scene_root() != stage or Exchange.token(Exchange.snapshot(stage)) != expected_base:
			DirectPaste.log_event("apply rejected: active stage or revision changed", trace)
			finish_preview("error", "The active stage changed. Copy the stage again.")
			return
		Exchange.commit(get_undo_redo(), stage, changes)
		DirectPaste.log_event("changes applied to editor scene", trace)
		finish_preview("partial" if additions_only else "applied", "Godot に反映しました。")
	# Remove any previously dismissed preview callback before connecting.
	for connection in confirm.confirmed.get_connections():
		confirm.confirmed.disconnect(connection.callable)
	confirm.confirmed.connect(accept, CONNECT_ONE_SHOT)
	confirm.dialog_text = "%d tile writes, %d tile removals/replacements, %d marker moves.\n%d checkpoints added, %d removed." % [
		changes.next.size(), changes.old.size(), changes.markers.size(),
		changes.checkpoints_added.size(), changes.checkpoints_removed.size()]
	if merged_changes:
		confirm.dialog_text = "Godot 側の変更を保持し、MapEdit の差分を反映します。\n" + confirm.dialog_text
	if additions_only:
		confirm.dialog_text = ("Godot 側の配置が取り込み後に変更されています。\n"
			+ "新規チェックポイント %d 件だけを追加します。タイル、既存マーカー、削除は反映しません。") % changes.checkpoints_added.size()
	EditorInterface.get_base_control().get_window().grab_focus()
	preview_trace = trace
	preview_completion = completion
	confirm.popup_centered()
	DirectPaste.log_event("preview opened", trace)
	confirm.grab_focus()
	return {"status": "preview", "message": "Godot で差分を確認してください。"}

func cancel_preview() -> void:
	DirectPaste.log_event("preview canceled", preview_trace)
	finish_preview("canceled", "Godot で貼り付けをキャンセルしました。")

func finish_preview(status: String, body: String) -> void:
	var completion := preview_completion
	preview_completion = Callable()
	if completion.is_valid():
		completion.call(status, body)
	elif status == "error":
		show_message(body)

func show_message(body: String) -> void:
	message.dialog_text = body
	message.popup_centered()

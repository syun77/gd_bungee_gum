@tool
extends RefCounted

const PORT := 47653
const MAX_BYTES := 2 * 1024 * 1024
const TIMEOUT_MS := 3000

var server := TCPServer.new()
var peer: StreamPeerTCP
var payload := PackedByteArray()
var deadline := 0
var trace := "-"

func start() -> Error:
	var error := server.listen(PORT, "127.0.0.1")
	log_event("listen 127.0.0.1:%d: %s" % [PORT, error_string(error)])
	return error

func stop() -> void:
	close_peer()
	server.stop()

func poll(paste: Callable) -> void:
	if not server.is_listening():
		return
	if peer == null:
		if not server.is_connection_available():
			return
		peer = server.take_connection()
		if peer == null:
			return
		log_event("connection accepted")
		deadline = Time.get_ticks_msec() + TIMEOUT_MS
	peer.poll()
	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		log_event("connection closed before request completed: status=%d bytes=%d" % [peer.get_status(), payload.size()])
		close_peer()
		return
	if deadline == 0:
		return
	if Time.get_ticks_msec() >= deadline:
		log_event("request timed out: bytes=%d" % payload.size())
		close_peer()
		return
	var available := peer.get_available_bytes()
	if available == 0:
		return
	if payload.size() + available > MAX_BYTES:
		reply("error", "MapEdit request is too large.")
		return
	var chunk := peer.get_data(available)
	if chunk[0] != OK:
		log_event("read failed: " + error_string(chunk[0]))
		close_peer()
		return
	payload.append_array(chunk[1])
	if payload[payload.size() - 1] != 10:
		return
	var json := payload.get_string_from_utf8()
	trace = json.sha256_text().left(12)
	log_event("request received: bytes=%d" % payload.size(), trace)
	var request_peer := peer
	var complete := func(status: String, message: String) -> void:
		if peer == request_peer:
			reply(status, message)
	var result: Dictionary = paste.call(json, complete)
	if result.status == "preview":
		deadline = 0
	else:
		reply(result.status, result.message)

func reply(status: String, message: String) -> void:
	var error := peer.put_data(JSON.stringify({"status": status, "message": message}).to_utf8_buffer())
	log_event("reply status=%s write=%s" % [status, error_string(error)], trace)
	close_peer()

func close_peer() -> void:
	if peer:
		peer.disconnect_from_host()
		peer = null
	payload.clear()
	trace = "-"

static func log_event(message: String, request_id := "-") -> void:
	print("%sZ [MapEditPaste] [%s] %s" % [Time.get_datetime_string_from_system(true), request_id, message])

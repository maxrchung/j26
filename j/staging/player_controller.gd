extends Node

@export var nameField: LineEdit
@export var joinButton: Button
@export var lobbyList: ItemList

var socket = WebSocketPeer.new()
var json = JSON.new()

enum ClientState {
	Connecting,
	Idle,
	Failed,
	FetchingLobbies,
}

var clientState: ClientState = ClientState.Connecting

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	joinButton.pressed.connect(_do_join)
	socket.connect_to_url("ws://localhost:5092/api/v1/game/socket")

func _do_join() -> void:
	name = nameField.text

func _handle_rsp(text: String) -> void:
	var err = json.parse(text)
	if err != OK:
		print("Failed to parse JSON: %s" % json.error_string)
		return
	var d = json.data
	print(d)
	if "lobbyList" in d:
		lobbyList.clear()
		for lobby in d.lobbyList:
			lobbyList.add_item(lobby.name)

func _process_socket() -> void:
	if clientState == ClientState.Failed: return
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_CLOSED:
		print("websocket closed :(")
		clientState = ClientState.Failed
	if state != WebSocketPeer.STATE_OPEN: return
	if clientState == ClientState.Connecting:
		print("websocket connected")
		clientState = ClientState.Idle
		socket.send_text('{"id": 0, "connect": {"version": "hi"}}')
		socket.send_text('{"id": 0, "getInfo": "lobbies"}')
	while socket.get_available_packet_count() > 0:
		var packet = socket.get_packet()
		var text = packet.get_string_from_utf8()
		_handle_rsp(text)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_process_socket()
	pass

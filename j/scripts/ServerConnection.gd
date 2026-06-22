extends Node

class_name SrvCxn

enum ConnectionState {
	Initial,
	Connecting,
	Connected,
	Failed,
}

class LobbyEntry:
	var id: String
	var name: String
	var default: bool
	func _init(obj: Dictionary):
		id = obj.get("id")
		name = obj.get("name")
		default = false

class PlayerInfo:
	var id: String
	var name: String

	func _init(obj: Dictionary):
		id = obj.get("id")
		name = obj.get("name")

class LobbyInfo:
	var id: String
	var name: String
	var players: Array[PlayerInfo]

	func _init(obj: Dictionary):
		id = obj.get("id")
		name = obj.get("name")
		players = []
		for pObj in obj.get("players", []):
			players.append(PlayerInfo.new(pObj))

class RpcCard:
	var suit: String
	var value: String
	var face_up: bool

	func _init(obj: Dictionary):
		suit = obj.get("suit")
		value = obj.get("value")
		face_up = true

class RpcHand:
	var cards: Array[RpcCard]

	func _init(obj: Array):
		cards = []
		for c in obj:
			cards.append(RpcCard.new(c))

class PlayerHands:
	var hands: Dictionary[String, RpcHand] = {}

	func _init(obj: Array):
		hands = {}
		for p in obj:
			var id = p.get("id")
			var hand = RpcHand.new(p.get("cards", []))
			for i in range(p.cardCount - hand.cards.size()):
				var fakeCard = RpcCard.new({"suit": "Spade", "value": "Two"})
				fakeCard.face_up = false
				hand.cards.append(fakeCard)
			hands[id] = hand

class EmergencyMeetingInfo:
	var active: bool
	var votes_for: Array
	var votes_against: Array

	func _init(obj: Dictionary):
		active = obj.get("isActive")
		votes_for = obj.get("votesFor")
		votes_against = obj.get("votesAgainst")

# signals
signal connection_state_changed(new_state: ConnectionState)
signal lobby_list_updated(lobbies: Array[LobbyEntry])
signal lobby_info_updated(info: LobbyInfo)
signal hands_updated(hands: PlayerHands)
signal player_id_updated(player_id: String)
signal emergency_meeting_updated(info: EmergencyMeetingInfo)
signal bid_changed(bid: RpcHand)
signal game_started(players: Array[PlayerInfo])
signal turn_player_changed(player_id: String)
signal bid_player_changed(player_id: String)

# publics
var CurrentPlayerID: String = ""
var TurnPlayerID: String = ""
var BidPlayerID: String = ""

# privates
var _cxnState: ConnectionState = ConnectionState.Initial
var _socket: WebSocketPeer = WebSocketPeer.new()
var _json = JSON.new()

# public methods
func ws_connect(url: String) -> void:
	print("connecting to " + url)
	if _socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		_socket.close()
	_socket.connect_to_url(url)

func join(lobbyId: String, playerName: String) -> void:
	_invoke("join", {"lobbyId": lobbyId, "playerName": playerName})

func create_lobby(lobbyName: String) -> void:
	_invoke("create", {"playerName": lobbyName})

func start_game() -> void:
	_invoke("invokeCtl", "StartGame")

func vote_for() -> void:
	_invoke("invokeCtl", "EmergencyMeetingVoteFor")

func vote_against() -> void:
	_invoke("invokeCtl", "EmergencyMeetingVoteAgainst")

func refresh_info() -> void:
	_invoke("getInfo", "Lobbies")

func submit_bid(data: Array) -> void:
	_invoke("bid", {"cards": data})

# private methods
func _invoke(name_: String, data: Variant) -> void:
	var msg = {"id": 0}
	msg[name_] = data
	_socket.send_text(JSON.stringify(msg))

func _on_connect():
	_invoke("connect", {"version": "1"})
	refresh_info()

func _parse_lobby_list(data: Dictionary) -> void:
	var lobbies: Array[LobbyEntry] = []
	var targetLobby = data.get("justCreated", "")
	for lobby_data in data.lobbies:
		var lobby_entry = LobbyEntry.new(lobby_data)
		if lobby_entry.id == targetLobby:
			lobby_entry.default = true
		lobbies.append(lobby_entry)
	lobby_list_updated.emit(lobbies)

func _parse_lobby_change(data: Dictionary) -> void:
	var lobby_info = LobbyInfo.new(data)
	lobby_info_updated.emit(lobby_info)

func _parse_game_state_change(data: Dictionary) -> void:
	var event = data.eventType
	if event == "RoundStart":
		StateManager.change_state(StateMgr.GameStateT.Round)
		var roundNumber: int = data.currentRound.roundNumber
		if roundNumber == 1:
			# Game just started, init other players
			game_started.emit(data.players)
			#TableController.init_table(myPlayerId, d.gameStateUpdateEvent.players)
	elif event == "GameOver":
		StateManager.change_state(StateMgr.GameStateT.GameOver)
	
func _parse_player_hands(data: Array) -> void:
	var hands = PlayerHands.new(data)
	hands_updated.emit(hands)

func _handle_msg(text: String) -> void:
	print("rpc: %s" % text)
	var err = _json.parse(text)
	if err != OK:
		print("Failed to parse JSON: %s" % _json.error_string)
		return
	var d = _json.data

	if "localIdChange" in d:
		CurrentPlayerID = d["localIdChange"]
		player_id_updated.emit(CurrentPlayerID)

	if "currentPlayer" in d:
		TurnPlayerID = d["currentPlayer"]
		turn_player_changed.emit(TurnPlayerID)
	
	if "bidPlayer" in d:
		BidPlayerID = d["bidPlayer"]
		bid_player_changed.emit(BidPlayerID)

	if "lobbyList" in d:
		_parse_lobby_list(d["lobbyList"])

	if "lobbyChange" in d:
		_parse_lobby_change(d["lobbyChange"])
	
	if "gameStateUpdateEvent" in d:
		_parse_game_state_change(d["gameStateUpdateEvent"])

	if "playerHands" in d:
		_parse_player_hands(d["playerHands"])

	if "emergencyMeeting" in d:
		var meetingInfo = EmergencyMeetingInfo.new(d["emergencyMeeting"])
		if meetingInfo.active:
			TurnPlayerID = "" # nobodys turn
			turn_player_changed.emit(TurnPlayerID)
			StateManager.change_state(StateMgr.GameStateT.EmergencyMeeting)
		emergency_meeting_updated.emit(meetingInfo)
	
	if "bid" in d:
		var bid = RpcHand.new(d["bid"])
		bid_changed.emit(bid)
	
func _state_change(new_state: ConnectionState) -> void:
	if new_state == ConnectionState.Connected:
		_on_connect()

func _ready() -> void:
	var DEFAULT_HOST = "ws://localhost:5092/" if OS.is_debug_build() else "wss://bsq.up.railway.app/"
	ws_connect(DEFAULT_HOST + "api/v1/game/socket")
	connection_state_changed.connect(_state_change)

func _transition_cxn_state(new_state: ConnectionState) -> void:
	if _cxnState != new_state:
		_cxnState = new_state
		connection_state_changed.emit(new_state)

func _check_socket_state(socketState: WebSocketPeer.State) -> void:
	if socketState == WebSocketPeer.STATE_CONNECTING:
		_transition_cxn_state(ConnectionState.Connecting)
	elif socketState == WebSocketPeer.STATE_OPEN:
		_transition_cxn_state(ConnectionState.Connected)
	elif socketState == WebSocketPeer.STATE_CLOSED:
		_transition_cxn_state(ConnectionState.Failed)

func _process_socket() -> void:
	_socket.poll()
	var socketState = _socket.get_ready_state()
	_check_socket_state(socketState)
	if socketState == WebSocketPeer.STATE_OPEN:
		while _socket.get_available_packet_count() > 0:
			var packet = _socket.get_packet()
			var text = packet.get_string_from_utf8()
			_handle_msg(text)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_process_socket()

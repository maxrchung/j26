extends Node

@export var nameField: LineEdit
@export var joinButton: Button
@export var lobbyList: ItemList

var socket = WebSocketPeer.new()
var json = JSON.new()
var itemMap: Dictionary[int, String] = {}
var is_connected = false

enum ClientState {
	Connecting,
	Idle,
	Failed,
	FetchingLobbies,
}

var clientState: ClientState = ClientState.Connecting

var myLobbyId
var myPlayerId
var currentPlayer
var bidPlayer

var playerHands

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	joinButton.pressed.connect(_do_join)
	$"../EmergencyMeeting".emergency.connect(_on_emergency_meeting_button_pressed)
	$"../EmergencyMeeting".vote_no_bs.connect(_on_vote_for_button_pressed)
	$"../EmergencyMeeting".vote_bs.connect(_on_vote_against_button_pressed)

func _on_connect_button_pressed() -> void:
	var host = $"../LobbyStuff/ConnectText".text
	socket.connect_to_url("ws://" + host + ":5092/api/v1/game/socket")
	is_connected = true

func _invoke(name: String, value):
	var body = {"id": 0}
	body[name] = value
	socket.send_text(JSON.stringify(body))

func _do_join() -> void:
	var name = nameField.text
	var lobbyId = itemMap[lobbyList.get_selected_items()[0]]
	print("joining ", lobbyId, " as ", name)
	_invoke("join", {"lobbyId": lobbyId, "playerName": name})
	$"../LobbyStuff".visible = false
	
	$"../PlayersLabel".visible = true
	$"../PlayerInfos".visible = true
	$"../StartButton".visible = true

	

func _handle_rsp(text: String) -> void:
	var err = json.parse(text)
	if err != OK:
		print("Failed to parse JSON: %s" % json.error_string)
		return
	var d = json.data
	print(d)
	
	if "gameStateUpdateEvent" in d:
		var event = d.gameStateUpdateEvent
		if event.eventType == "RoundStart":
			bidPlayer = null
			currentPlayer = null
			$"../EmergencyMeeting".reset()
			
			$"../Hand".visible = true
			$"../StartButton".visible = false
			$"../CurrentText".visible = true
			$"../BidMpregs".visible = true
			$"../BidButton".visible = true
			$"../RoundNumberLabel".visible = true
			
		elif event.eventType == "GameOver":
			print("GAME OVER")
	
	if "lobbyList" in d:
		lobbyList.clear()
		itemMap = {}
		for lobby in d.lobbyList:
			itemMap[lobbyList.add_item(lobby.name)] = lobby.id
			
	if "lobbyChange" in d:
		myLobbyId = d.lobbyChange.id
		var players = d.lobbyChange.players
		
		playerHands = []
		for player in players:
			playerHands.append({
				"id": player.id,
				"name": player.name,
				"cardCount": 0,
				"cards": []
			})	
		$"../PlayerInfos".update_players(playerHands, myPlayerId)
		
	if "localIdChange" in d:
		myPlayerId = d.localIdChange
		
	if "playerHands" in d:
		playerHands = d.playerHands
		$"../PlayerInfos".update_players(playerHands, myPlayerId)
		
		for playerHand in playerHands:
			if myPlayerId == playerHand.id:
				$"../Hand".update_cards(playerHand.cards)
				
	if "gameStateUpdateEvent" in d:
		$"../RoundNumberLabel".text = "Rounds left: " + str(int(7 - d.gameStateUpdateEvent.currentRound.roundNumber))
				
	if "currentPlayer" in d:
		currentPlayer = d.currentPlayer
		
		$"../CurrentText".text = "Current player: " + currentPlayer
		
		if currentPlayer == myPlayerId:
			$"../BidButton".visible = true
		else:
			$"../BidButton".visible = false
	
	if "bidPlayer" in d:
		bidPlayer = d.bidPlayer
		$"../EmergencyMeeting".update_button(myPlayerId, bidPlayer)
		
	if "bid" in d:
		var bid = d.bid
		$"../BidMpregs".set_cards(bid)
		
	if "emergencyMeeting" in d:
		$"../EmergencyMeeting".update_state(myPlayerId, bidPlayer, d.emergencyMeeting)
		$"../BidButton".visible = false

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
		_invoke("connect", {"version": "hi"})
		_invoke("getInfo", "lobbies")
	while socket.get_available_packet_count() > 0:
		var packet = socket.get_packet()
		var text = packet.get_string_from_utf8()
		_handle_rsp(text)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if is_connected:
		_process_socket()
	pass


func _on_send_json_button_pressed() -> void:
	var text = $"../SendJsonText".text
	socket.send_text(text)


func _on_start_button_pressed() -> void:
	_invoke("invokeCtl", "StartGame")
	

func _on_emergency_meeting_button_pressed() -> void:
	_invoke("invokeCtl", "EmergencyMeetingVoteAgainst")

func _on_vote_for_button_pressed() -> void:
	_invoke("invokeCtl", "EmergencyMeetingVoteFor")

func _on_vote_against_button_pressed() -> void:
	_invoke("invokeCtl", "EmergencyMeetingVoteAgainst")


func _on_bid_button_pressed() -> void:
	var cards = $"../BidMpregs".get_cards()
	_invoke("bid", { "cards": cards } )

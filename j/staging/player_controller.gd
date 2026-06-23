extends Node

@export var nameField: LineEdit
@export var joinButton: Button
@export var lobbyList: ItemList
@onready var generic_click: AudioStreamPlayer = $"../generic_click"
@onready var emergency_sfx: AudioStreamPlayer = $"../Emergency_sfx"

var socket = WebSocketPeer.new()
var json = JSON.new()
var itemMap: Dictionary[int, String] = {}
var is_connected = false
var is_game_donezo = false

enum ClientState {
	Connecting,
	Idle,
	Failed,
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
	socket.close()
	socket = WebSocketPeer.new()
	generic_click.play()
	
	if OS.is_debug_build():
		socket.connect_to_url("ws://localhost:5092/api/v1/game/socket")
	else:
		socket.connect_to_url("wss://bsq.up.railway.app/api/v1/game/socket")
	
	clientState = ClientState.Connecting
	
	lobbyList.clear()
	
	$"../LobbyStuff/LineEdit".visible = false
	$"../LobbyStuff/Button".visible = false
	$"../LobbyStuff/CreateButton".visible = false
	

func _invoke(name: String, value):
	var body = {"id": 0}
	body[name] = value
	socket.send_text(JSON.stringify(body))

func _do_join() -> void:
	var name = nameField.text
	
	if name.length() == 0:
		return
		
	if lobbyList.get_selected_items().size() == 0:
		return
		
	if clientState != ClientState.Idle:
		return
	
	var lobbyId = itemMap[lobbyList.get_selected_items()[0]]
	print("joining ", lobbyId, " as ", name)
	generic_click.play()
	_invoke("join", {"lobbyId": lobbyId, "playerName": name})
	$"../LobbyStuff".visible = false
	
	$"../LobbyNameLabel".visible = true
	$"../PlayersLabel".visible = true
	$"../PlayerInfos".visible = true
	$"../StartButton".visible = true
	$"../QuitButton".visible = true

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
			$"../Hand".force_show()
			$"../StartButton".visible = false
			$"../CurrentText".visible = true
			$"../BidMpregs".visible = true
			$"../BidMpregs".set_cards([])
			$"../BidButton".visible = true
			$"../RoundNumberLabel".visible = true
			
			
		elif event.eventType == "GameOver":
			$"../EmergencyMeeting".visible = false
			$"../Hand".visible = false
			$"../BidMpregs".visible = false
			$"../BidButton".visible = false
			$"../EmergencyMeeting".visible = false
			$"../CurrentText".visible = false
			$"../RoundNumberLabel".visible = false
			
			$"../WinnerLabel".visible = true
			var winnerId = event.winner
			var winnerName = winnerId
			for playerHand in playerHands:
				if winnerId == playerHand.id:
					winnerName = playerHand.name
					break
			$"../WinnerLabel".text = "Winner: " + winnerName
			is_game_donezo = true
			return
	
	if "lobbyList" in d:
		lobbyList.clear()
		itemMap = {}
		for lobby in d.lobbyList:
			itemMap[lobbyList.add_item(lobby.name)] = lobby.id
			
	if "lobbyChange" in d:
		myLobbyId = d.lobbyChange.id
		var players = d.lobbyChange.players
		
		$"../LobbyNameLabel".text = "Lobby: " + d.lobbyChange.name
		
		playerHands = []
		for player in players:
			playerHands.append({
				"id": player.id,
				"name": player.name,
				"cardCount": 0,
				"score": 0,
				"cards": []
			})	
		$"../PlayerInfos".update_players(playerHands, myPlayerId)
		$"../PlayersLabel".text = "Players: " + str(playerHands.size())
		
	if "playerHands" in d:
		playerHands = d.playerHands
		$"../PlayerInfos".update_players(playerHands, myPlayerId)
		
		for playerHand in playerHands:
			if myPlayerId == playerHand.id:
				$"../Hand".update_cards(playerHand.cards)
		
	if is_game_donezo:
		return
		
	if "localIdChange" in d:
		myPlayerId = d.localIdChange
				
	if "gameStateUpdateEvent" in d:
		var roundNumber: int = int(d.gameStateUpdateEvent.currentRound.roundNumber)
		$"../RoundNumberLabel".text = "Rounds left: " + str(10 -roundNumber)
				
	if "currentPlayer" in d:
		currentPlayer = d.currentPlayer
		
		var playerName = currentPlayer
		for playerHand in playerHands:
			if currentPlayer == playerHand.id:
				playerName = playerHand.name
				break
		
		if currentPlayer == myPlayerId:
			$"../BidButton".visible = true
			$"../BidMpregs".enable(true)
			$"../CurrentText".text = "Current turn: " + playerName + " (You)"
		else:
			$"../BidButton".visible = false
			$"../BidMpregs".enable(false)
			$"../CurrentText".text = "Current turn: " + playerName
	
	if "bidPlayer" in d:
		bidPlayer = d.bidPlayer
		$"../EmergencyMeeting".update_button(myPlayerId, bidPlayer)
		
	if "ok" in d:
		if d.ok.message == "Invalid bid":
			$"../StatusLabel".visible = true
			$"../StatusLabel".text = "Hand score too low"
		elif d.ok.message == "It was BS":
			$"../StatusLabel".visible = true
			$"../StatusLabel".text = d.ok.message
		elif d.ok.message == "It was not BS":
			$"../StatusLabel".visible = true
			$"../StatusLabel".text = d.ok.message
		
	if "bid" in d:
		var bid = d.bid
		$"../BidMpregs".set_cards(bid)
		$"../StatusLabel".visible = false
		
	if "emergencyMeeting" in d:
		$"../EmergencyMeeting".update_state(myPlayerId, bidPlayer, d.emergencyMeeting)
		$"../BidButton".visible = false
		$"../BidMpregs".enable(false)
		$"../StatusLabel".text = "Vote for BS"
		$"../StatusLabel".visible = true
		


func _process_socket() -> void:
	
	socket.poll()
	
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_CLOSED and clientState != ClientState.Connecting:
		print("websocket closed :(")
		clientState = ClientState.Failed
	elif state == WebSocketPeer.STATE_OPEN and clientState == ClientState.Connecting:
		print("websocket connected")
		clientState = ClientState.Idle
		_invoke("connect", {"version": "hi"})
		_invoke("getInfo", "lobbies")
		$"../LobbyStuff/LineEdit".visible = true
		$"../LobbyStuff/Button".visible = true
		$"../LobbyStuff/CreateButton".visible = true
		
	if clientState == ClientState.Failed: return
		
	while socket.get_available_packet_count() > 0:
		var packet = socket.get_packet()
		var text = packet.get_string_from_utf8()
		_handle_rsp(text)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_process_socket()


func _on_send_json_button_pressed() -> void:
	var text = $"../SendJsonText".text
	socket.send_text(text)


func _on_start_button_pressed() -> void:
	if not playerHands or playerHands.size() < 2:
		print('preventing start game because too few people')
		return
	generic_click.play()
	_invoke("invokeCtl", "StartGame")
	

func _on_emergency_meeting_button_pressed() -> void:
	emergency_sfx.play()
	_invoke("invokeCtl", "EmergencyMeetingVoteAgainst")

func _on_vote_for_button_pressed() -> void:
	generic_click.play()
	_invoke("invokeCtl", "EmergencyMeetingVoteFor")

func _on_vote_against_button_pressed() -> void:
	generic_click.play()
	_invoke("invokeCtl", "EmergencyMeetingVoteAgainst")


func _on_bid_button_pressed() -> void:
	generic_click.play()
	var cards = $"../BidMpregs".get_cards()
	$"../StatusLabel".visible = false
	
	if cards.size() == 0:
		print("no cards, so not submitting")
		$"../StatusLabel".visible = true
		$"../StatusLabel".text = "Hand score too low"
		return
	
	_invoke("bid", { "cards": cards } )


func _on_create_button_pressed() -> void:
	var name = nameField.text
	
	if name.length() == 0:
		return
		
	if clientState != ClientState.Idle:
		return
	generic_click.play()
	_invoke("create", {"playerName": name})
		
	$"../LobbyStuff".visible = false
	$"../LobbyNameLabel".visible = true
	$"../PlayersLabel".visible = true
	$"../PlayerInfos".visible = true
	$"../StartButton".visible = true
	$"../QuitButton".visible = true

func _on_quit_button_pressed() -> void:
	generic_click.play()
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

extends Control

@onready var HelpButton = $"Titlebar/TitleMargin/TitleContainer/HelpButton"
@onready var HelpPanel = $"HelpPanel"
@onready var LobbyList = $"ConnectionTabs/JoinContainer/VBoxContainer/LobbyList" as ItemList

@onready var ConnectionTabs = $"ConnectionTabs" as TabContainer

@onready var PlayerNameField = $"ConnectionTabs/JoinContainer/VBoxContainer/LobbyBottomContainer/PlayerName" as LineEdit
@onready var JoinButton = $"ConnectionTabs/JoinContainer/VBoxContainer/LobbyBottomContainer/JoinButton" as Button

@onready var LobbyNameField = $"ConnectionTabs/CreateContainer/VBoxContainer/HBoxContainer/LobbyNameInput" as LineEdit
@onready var LobbyCreateButton = $"ConnectionTabs/CreateContainer/VBoxContainer/HBoxContainer/LobbyCreateButton" as Button

@onready var RefreshButton = $"ConnectionTabs/JoinContainer/VBoxContainer/LobbyTopContainer/RefreshButton" as Button

var _lobbyMap: Dictionary[int, String] = {}

func _toggle_help():
	HelpPanel.visible = not HelpPanel.visible

func _name_validation(new_name: String) -> void:
	if new_name.is_empty():
		JoinButton.disabled = true
	else:
		JoinButton.disabled = false

func _join_lobby(_trash: String = "") -> void:
	if JoinButton.disabled:
		return
	var lobbyId = _lobbyMap.get(LobbyList.get_selected_items()[0])
	var playerName = PlayerNameField.text
	print("joining lobby ", lobbyId, " with name ", playerName)
	ServerConnection.join(lobbyId, playerName)
	StateManager.change_state(StateManager.GameStateT.Lobby)

func _lobby_name_validation(new_name: String) -> void:
	if new_name.is_empty():
		LobbyCreateButton.disabled = true
	else:
		LobbyCreateButton.disabled = false

func _create_lobby(_trash: String = "") -> void:
	var lobbyName = LobbyNameField.text
	print("creating lobby with name ", lobbyName)
	ServerConnection.create_lobby(lobbyName)
	ConnectionTabs.current_tab = 0

func _refresh_lobbies() -> void:
	RefreshButton.disabled = true
	ServerConnection.refresh_info()

func _handle_cxn_state_change(new_state: ServerConnection.ConnectionState) -> void:
	if new_state == ServerConnection.ConnectionState.Connected:
		ConnectionTabs.visible = true
		$ConnectingContainer.visible = false
	else:
		ConnectionTabs.visible = false
		$ConnectingContainer.visible = true
		HelpButton.visible = true

func _handle_lobby_list_updated(lobbies: Array[ServerConnection.LobbyEntry]) -> void:
	LobbyList.clear()
	_lobbyMap.clear()
	var forceIdx = 0
	for lobby in lobbies:
		var idx = LobbyList.add_item(lobby.name)
		_lobbyMap[idx] = lobby.id
		if lobby.default:
			forceIdx = idx
	LobbyList.select(forceIdx)
	RefreshButton.disabled = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ConnectionTabs.current_tab = 0

	ServerConnection.connection_state_changed.connect(_handle_cxn_state_change)
	ServerConnection.lobby_list_updated.connect(_handle_lobby_list_updated)

	PlayerNameField.text_changed.connect(_name_validation)
	PlayerNameField.text_submitted.connect(_join_lobby)
	JoinButton.pressed.connect(_join_lobby)

	LobbyNameField.text_changed.connect(_lobby_name_validation)
	LobbyNameField.text_submitted.connect(_create_lobby)
	LobbyCreateButton.pressed.connect(_create_lobby)

	RefreshButton.pressed.connect(_refresh_lobbies)

	HelpButton.connect("button_up", _toggle_help)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

extends Control

@onready var LobbyTitle = $"Titlebar/MarginContainer/Control/LobbyTitle" as Label
@onready var StartButton = $"BottomContainer/MarginContainer/StartButton" as Button

func _start_game_pressed() -> void:
	ServerConnection.start_game()

func _handle_lobby_info_updated(info: SrvCxn.LobbyInfo) -> void:
	print("lobby ", info)
	LobbyTitle.text = info.name
	StartButton.disabled = info.players.size() < 2
	if StartButton.disabled:
		StartButton.text = "Waiting for players..."
	else:
		StartButton.text = "Start Game"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ServerConnection.lobby_info_updated.connect(_handle_lobby_info_updated)
	StartButton.pressed.connect(_start_game_pressed)

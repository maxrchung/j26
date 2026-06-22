extends Node2D

@onready var MenuSceneI = $BaseScenes/MenuScene
@onready var LobbySceneI = $BaseScenes/LobbyScene
@onready var RoundSceneI = $BaseScenes/RoundScreen

func _on_state_change(new_state: StateMgr.GameStateT) -> void:
	match new_state:
		StateMgr.GameStateT.Menu:
			MenuSceneI.visible = true
			LobbySceneI.visible = false
			RoundSceneI.visible = false
		StateMgr.GameStateT.Lobby:
			MenuSceneI.visible = false
			LobbySceneI.visible = true
			RoundSceneI.visible = false
		StateMgr.GameStateT.Round:
			MenuSceneI.visible = false
			LobbySceneI.visible = false
			RoundSceneI.visible = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	StateManager.state_changed.connect(_on_state_change)
	StateManager.change_state(StateMgr.GameStateT.Menu)
	pass # Replace with function body.

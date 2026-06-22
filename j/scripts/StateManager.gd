extends Node

class_name StateMgr

enum GameStateT {
	Menu,
	Lobby,
	Round,
	GameOver
}

signal state_changed(new_state: GameStateT)

func change_state(new_state: GameStateT) -> void:
	state_changed.emit(new_state)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

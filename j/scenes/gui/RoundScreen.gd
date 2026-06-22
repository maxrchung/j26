extends Control

@onready var OwnHand = $"OwnHand" as BidView

func _on_playerid_update(player_id: String) -> void:
	OwnHand.OwnerID = player_id

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ServerConnection.player_id_updated.connect(_on_playerid_update)

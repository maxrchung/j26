extends Control

@onready var BidButton = $ExtraButtons/BidButton as Button
@onready var CallButton = $ExtraButtons/CallButton as Button
@onready var BidEntry = $BidEntry as BidEntry

func _submit_bid() -> void:
	var hand = BidEntry.serialize()
	print("submitting bid ", hand)
	ServerConnection.submit_bid(hand)

func _call_meeting() -> void:
	ServerConnection.vote_against()

func _update_player_turn(player_id: String) -> void:
	var our_turn = player_id == ServerConnection.CurrentPlayerID
	BidButton.visible = our_turn

func _bid_player_changed(player_id: String) -> void:
	var our_bid = player_id == ServerConnection.CurrentPlayerID
	CallButton.visible = !our_bid

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ServerConnection.turn_player_changed.connect(_update_player_turn)
	ServerConnection.bid_player_changed.connect(_bid_player_changed)
	CallButton.visible = false
	BidButton.visible = false
	BidButton.pressed.connect(_submit_bid)
	CallButton.pressed.connect(_call_meeting)
	pass

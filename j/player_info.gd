extends Node2D

var player_name = ""
var card_count = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Name.text = "Name: " + player_name
	$CardCount.text = "Cards: " + str(card_count)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

extends Node2D

@export var player_info_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_players(player_hands, my_player_id):
	# Clear existing
	for child in get_children():
		child.queue_free()
	
	for i in player_hands.size():
		var player_hand = player_hands[i]
		var player_info = player_info_scene.instantiate()
		
		if player_hand.id == my_player_id:
			player_info.player_name = player_hand.name + ' (You)'
		else:
			player_info.player_name = player_hand.name
		player_info.card_count = player_hand.cardCount
		player_info.position = Vector2(0, i * 60)
		add_child(player_info)

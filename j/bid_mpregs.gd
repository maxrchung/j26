extends Node2D

@export var bid_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_cards([])
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_cards():
	var cards = []
	for child in get_children():
		var card = child.get_card()
		if card == null:
			continue
		
		cards.append(card)
		
	return cards
	
func set_cards(cards):
	# Clear existing
	for child in get_children():
		child.queue_free()
		
	for i in 5:
		var bid = bid_scene.instantiate()
		bid.position = Vector2(i * 120, 0)
		
		if i < cards.size():
			var card = cards[i]
			bid.set_card(card.suit, card.number)
			
		add_child(bid)

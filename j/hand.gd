extends Node2D

@export var card_scene: PackedScene

var is_shown = true
var new_cards = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ShowButton.z_index = 999

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func force_show():
	is_shown = true
	$ShowButton.text = "Hide"
	update_cards(new_cards)

func update_cards(cards):
	new_cards = cards
	
	# Remove old
	for child in get_children():
		if child is PlayingCard:
			child.queue_free()
		
	var count = cards.size()
	if count == 0:
		return
		
	# Dedicate at least 250 for the main center card
	var width = 250
	
	# Add 50 for other cards
	if (count > 1):
		width += (count - 1) * 50
		
	var screen_size = get_viewport().get_visible_rect().size
	
	# Half screen size - half total width + account for anchor
	var left = screen_size.x / 2 - width / 2 + 125
	
	for i in count:
		var card = card_scene.instantiate()
		card.suit = PlayingCard.Suit[cards[i]["suit"]]
		
		var value = cards[i]["value"]
		var number = 2;
		
		if value == "Two":
			number = 2
		elif value == "Three":
			number = 3
		elif value == "Four":
			number = 4
		elif value == "Five":
			number = 5
		elif value == "Six":
			number = 6
		elif value == "Seven":
			number = 7
		elif value == "Eight":
			number = 8
		elif value == "Nine":
			number = 9
		elif value == "Ten":
			number = 10
		elif value == "Jack":
			number = 11
		elif value == "Queen":
			number = 12
		elif value == "King":
			number = 13
		elif value == "Ace":
			number = 14
		
		card.number = number
		card.position = Vector2(
			left + i * 50,
			screen_size.y + 50
		)
		if is_shown:
			card.face_up = true
		else:
			card.face_up = false
		
		add_child(card)
		

func reset_cards():
	update_cards([])

func randomize_cards():
	var count = randi_range(2, 5)
	
	var cards = []
	cards.resize(count)
	
	for i in count:
		cards[i] = {
			"suit": [
				PlayingCard.Suit.Spade,
				PlayingCard.Suit.Heart,
				PlayingCard.Suit.Club,
				PlayingCard.Suit.Diamond,
			].pick_random(),
			"number": randi_range(2, 14)
		}
		
	update_cards(cards)


func _on_button_pressed() -> void:
	if is_shown:
		is_shown = false
		$ShowButton.text = "Show"
		update_cards(new_cards)
	else:
		is_shown = true
		$ShowButton.text = "Hide"
		update_cards(new_cards)

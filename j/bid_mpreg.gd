extends Node2D

@export var index = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_card():
	if $SuitDropdown.selected < 0 or $NumberDropdown.selected < 0:
		return
	
	var card = {
		"suit": $SuitDropdown.get_item_text($SuitDropdown.selected),
		"value": $NumberDropdown.get_item_text($NumberDropdown.selected)
	}
	return card

func set_card(suit, number):
	for i in $SuitDropdown.item_count:
		if $SuitDropdown.get_item_text(i) == suit:
			$SuitDropdown.selected = i
			break
	
	for i in $NumberDropdown.item_count:
		if $NumberDropdown.get_item_text(i) == str(number):
			$NumberDropdown.selected = i
			break
	

extends Sprite2D

class_name Card

## `true` if card is facing you, `false` if facing away
@export var is_front = false

## Please gimme `spade`, `heart, `clover`, or `diamond`
@export var suit = 'spade'

## Number values match themselves, JQKA are 11, 12, 13, 14
@export var number = 2

## Width of card in pixels
static var width = 250

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Index
	# 00	front
	# 01	back
	# 02-14	spade 2-ace
	# 15-27 heart 2-ace
	# 28-40 clover 2-ace
	# 41-53 diamond 2-ace
	# 54	white border
	# 55	black border
	
	var face = $Face
	var border = $Border
	
	if not is_front:
		face.visible = false
		region_rect = Rect2(250, 0, 250, 350)
		border.region_rect = Rect2(54 * 250, 0, 250, 350)
		return
		
	region_rect = Rect2(0, 0, 250, 350)
	
	var index = 2
	
	# Skip depending on suit
	if suit == "spade":
		index += 0
	elif suit == "heart":
		index += 13
	elif suit == "clover":
		index += 26
	elif suit == "diamond":
		index += 39

	# Account for starting on 2
	index += number - 2

	face.region_rect = Rect2(index * 250, 0, 250, 350)
	face.visible = true
	
	border.region_rect = Rect2(55 * 250, 0, 250, 350)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

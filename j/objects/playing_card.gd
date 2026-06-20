extends Node2D

enum Suit {
	Spade,
	Heart,
	Diamond,
	Club
}

@export var face_up: bool = true
@export var suit: Suit = Suit.Spade
@export var number: int = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var back = $"BackTexture"
	var face = $"FaceTexture"
	var border = $"BorderTexture"
	
	if not face_up:
		back.region_rect = Rect2(250, 0, 250, 350)
		face.visible = false
		border.region_rect = Rect2(54 * 250, 0, 250, 350)
		return

	
	var index = number
	if suit == Suit.Spade:
		index += 0
	elif suit == Suit.Heart:
		index += 13
	elif suit == Suit.Club:
		index += 26
	elif suit == Suit.Diamond:
		index += 39

	back.region_rect = Rect2(0, 0, 250, 350)
	face.region_rect = Rect2(index * 250, 0, 250, 350)
	border.region_rect = Rect2(55 * 250, 0, 250, 350)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

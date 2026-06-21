@tool
extends AspectRatioContainer

class_name PlayingCard

@export var suit: SuitName = SuitName.Spade:
	set(v):
		suit = v
		_update_material()
@export var value: int = 2:
	set(v):
		value = v
		_update_material()
@export var face_up = true:
	set(v):
		face_up = v
		_update_material()

enum SuitName {
	Spade = 0,
	Heart = 1,
	Club = 2,
	Diamond = 3,
}

const SuitMap = [SuitName.Spade, SuitName.Heart, SuitName.Club, SuitName.Diamond]

@onready var texture_rect: TextureRect = $TextureRect

func _get_texture_rect() -> TextureRect:
	if is_node_ready():
		return texture_rect
	return get_node_or_null("TextureRect") as TextureRect

func _calc_offsets(suit_: SuitName, value_: int) -> Vector2i:
	return Vector2i(value_ - 2, int(suit_))

func _update_material():
	var card_texture_rect := _get_texture_rect()
	if card_texture_rect == null:
		return

	card_texture_rect.set_instance_shader_parameter("Offset", _calc_offsets(suit, value))
	card_texture_rect.set_instance_shader_parameter("FacingUp", face_up)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_material()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

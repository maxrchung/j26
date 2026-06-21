@tool
extends HBoxContainer

@export var show_stacked: bool = false:
	set(v):
		show_stacked = v
		_update_layout()

@export var face_up: bool = true:
	set(v):
		face_up = v
		_update_layout()

func _update_layout():
	self.add_theme_constant_override("separation", -100 if show_stacked else 10)
	for child in get_children():
		if child is PlayingCard:
			child.face_up = face_up

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_layout()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

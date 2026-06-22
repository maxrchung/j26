@tool
extends Button

class_name EditableCard

@export var is_editable: bool = false:
	set(v):
		is_editable = v
		CardMenu.visible = v

var _suit_inner: PlayingCard.SuitName = PlayingCard.SuitName.Special
var _value_inner: int = 1
var _was_ready: bool = false

@export var suit: PlayingCard.SuitName:
	set(v):
		_suit_inner = v
		_update_dropdowns()
		_update_material()
	get:
		return _suit_inner
@export var value: int:
	set(v):
		_value_inner = v
		_update_dropdowns()
		_update_material()
	get:
		return _value_inner

@onready var CardView = $PlayingCard as PlayingCard
@onready var CardMenu = $PlayingCard/CardMenu as PanelContainer
@onready var ValueSelect = $PlayingCard/CardMenu/MarginContainer/VBoxContainer/GridContainer/ValueOption as OptionButton
@onready var SuitSelect = $PlayingCard/CardMenu/MarginContainer/VBoxContainer/GridContainer/SuitOption as OptionButton

func is_blank() -> bool:
	return suit == PlayingCard.SuitName.Special and value == 1

func get_inner_suit() -> PlayingCard.SuitName:
	return _suit_inner

func get_suit_idx():
	match suit:
		PlayingCard.SuitName.Special: return 0
		PlayingCard.SuitName.Spade: return 1
		PlayingCard.SuitName.Heart: return 2
		PlayingCard.SuitName.Club: return 3
		PlayingCard.SuitName.Diamond: return 4

func _get_value_idx():
	return value - 1

const _SUIT_MAP = {
	PlayingCard.SuitName.Special: "FullBlank",
	PlayingCard.SuitName.Spade: "JustSpade",
	PlayingCard.SuitName.Heart: "JustHeart",
	PlayingCard.SuitName.Club: "JustClub",
	PlayingCard.SuitName.Diamond: "JustDiamond"
}

func _update_dropdowns():
	if !_was_ready:
		return
	ValueSelect.selected = _get_value_idx()
	SuitSelect.selected = get_suit_idx()

func _update_material():
	if !_was_ready:
		return
	if value == 1:
		CardView.suit = PlayingCard.SuitName.Special
		CardView.value = PlayingCard.SPECIAL_CARDS[_SUIT_MAP[suit]]
	else:
		if suit == PlayingCard.SuitName.Special:
			CardView.suit = PlayingCard.SuitName.Special
			CardView.value = PlayingCard.SPECIAL_CARDS.QuestionSuit
		else:
			CardView.suit = suit
			CardView.value = value

func _handle_suit_changed(idx):
	match idx:
		0: _suit_inner = PlayingCard.SuitName.Special
		1: _suit_inner = PlayingCard.SuitName.Spade
		2: _suit_inner = PlayingCard.SuitName.Heart
		3: _suit_inner = PlayingCard.SuitName.Club
		4: _suit_inner = PlayingCard.SuitName.Diamond
	_update_material()

func _handle_value_changed(idx):
	_value_inner = idx + 1
	_update_material()

func _toggle_menu() -> void:
	CardMenu.visible = !CardMenu.visible

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_was_ready = true
	ValueSelect.item_selected.connect(_handle_value_changed)
	SuitSelect.item_selected.connect(_handle_suit_changed)
	#pressed.connect(_toggle_menu)

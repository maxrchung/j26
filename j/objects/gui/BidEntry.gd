@tool
extends HBoxContainer

class_name BidEntry

var _was_ready: bool = false

@export var editable: bool = false:
	set(v):
		editable = v
		_update_editable()

@onready var _cards = [
	$Card1 as EditableCard,
	$Card2 as EditableCard,
	$Card3 as EditableCard,
	$Card4 as EditableCard,
	$Card5 as EditableCard,
]

const _SUIT_INDICES = [
	"None",
	"Spade",
	"Heart",
	"Club",
	"Diamond",
]
const _VALUE_INDICES = [
	"",
	"None",
	"Two",
	"Three",
	"Four",
	"Five",
	"Six",
	"Seven",
	"Eight",
	"Nine",
	"Ten",
	"Jack",
	"Queen",
	"King",
	"Ace"
]

func serialize() -> Array:
	var hand = []
	for card in _cards:
		if card.is_blank(): continue
		print(card.suit, card.value)
		hand.append({
			"Suit": _SUIT_INDICES[card.get_suit_idx()],
			"Value": _VALUE_INDICES[card.value]
		})
	return hand

func update_card(card: EditableCard, msg: SrvCxn.RpcCard) -> void:
	card.suit = PlayingCard.SuitName[msg.suit]
	card.value = BidView.CARD_VALUE_MAP[msg.value]

func blank_card(card: EditableCard) -> void:
	card.suit = PlayingCard.SuitName.Special
	card.value = 1

func _update_bid(bid: SrvCxn.RpcHand) -> void:
	for i in range(5):
		var card = _cards[i]
		if i < bid.cards.size():
			update_card(card, bid.cards[i])
		else:
			blank_card(card)
			card.visible = false

func _update_editable():
	if !_was_ready:
		return
	for child in get_children():
		if child is EditableCard:
			child.is_editable = editable

func _check_turn(turn_player: String) -> void:
	if ServerConnection.CurrentPlayerID == turn_player:
		editable = true
	else:
		editable = false
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_was_ready = true
	_update_editable()
	if !Engine.is_editor_hint():
		ServerConnection.bid_changed.connect(_update_bid)
		ServerConnection.turn_player_changed.connect(_check_turn)

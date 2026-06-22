@tool
extends HBoxContainer

class_name BidView

const CARD_PREFAB = preload("res://objects/PlayingCard.tscn")
const CARD_BASE_SIZE := Vector2(125, 175)
const NORMAL_SEPARATION := 10
const STACKED_SEPARATION := -100

var hand = [[PlayingCard.SuitName.Spade, 6, true], [PlayingCard.SuitName.Heart, 7, true]]

@export var OwnerID: String = ""

const CARD_VALUE_MAP = {
	"None": 1,
	"Two": 2,
	"Three": 3,
	"Four": 4,
	"Five": 5,
	"Six": 6,
	"Seven": 7,
	"Eight": 8,
	"Nine": 9,
	"Ten": 10,
	"Jack": 11,
	"Queen": 12,
	"King": 13,
	"Ace": 14,
}

@export var show_stacked: bool = false:
	set(v):
		show_stacked = v
		_update_layout()

@export var card_scale: float = 1.0:
	set(v):
		card_scale = v
		_update_layout()
		for child in get_children():
			if child is PlayingCard:
				_apply_card_layout(child)
		queue_sort()
		update_minimum_size()

func set_hand(new_hand):
	hand.clear()
	for card in new_hand:
		hand.append([PlayingCard.SuitName[card.suit], CARD_VALUE_MAP[card.value], card.face_up])
		print(hand[-1])
	_update_hand()

func _update_layout():
	self.add_theme_constant_override("separation", int(STACKED_SEPARATION * card_scale) if show_stacked else NORMAL_SEPARATION)
	queue_sort()
	update_minimum_size()

func _apply_card_layout(card: PlayingCard):
	card.custom_minimum_size = CARD_BASE_SIZE * card_scale

func _update_hand():
	for child in get_children():
		if child is PlayingCard:
			child.queue_free()
	for card in hand:
		var card_instance = CARD_PREFAB.instantiate() as PlayingCard
		card_instance.suit = card[0]
		card_instance.value = card[1]
		card_instance.face_up = card[2]
		_apply_card_layout(card_instance)
		add_child(card_instance)
	queue_sort()
	update_minimum_size()

func _handle_update(hands: SrvCxn.PlayerHands):
	var effectiveId = OwnerID
	if effectiveId == "$SELF":
		effectiveId = ServerConnection.CurrentPlayerID
	if effectiveId in hands.hands:
		var new_hand = hands.hands[effectiveId]
		set_hand(new_hand.cards)

func _handle_bid_update(bid: SrvCxn.RpcHand):
	if OwnerID == "$BID":
		set_hand(bid.cards)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_layout()
	_update_hand()
	if !Engine.is_editor_hint():
		ServerConnection.hands_updated.connect(_handle_update)
		ServerConnection.bid_changed.connect(_handle_bid_update)

class_name OtherPlayer extends Node

var player_id: int
var hand: Array[Card]

@onready var label: RichTextLabel = $Sprite2D/RichTextLabel
@onready var spawnPath: Path2D = $SpawnPath

var carddist_offset: float = 1.2 # ratio of card width apart that cards spawn

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# init player id text?
	label.text = "player_id: %d" % player_id

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_hand_size() -> int:
	return hand.size()
	
func reveal_hand() -> void:
	pass

# render hand spread?
func render_hand() -> void:
	var curve = spawnPath.curve
	var total_length = curve.get_baked_length()
	

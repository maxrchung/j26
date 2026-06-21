class_name OtherPlayer extends Node

var player_id: int
var hand: Array[Card]
var hand_size: int

@onready var label: RichTextLabel = $Sprite2D/RichTextLabel
@onready var spawnPath: Path2D = $SpawnPath

var carddist_offset: float = 0.8 # ratio of card width apart that cards spawn
var cardscale: float = 0.15 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# init player id text?
	label.text = "player_id: %d" % player_id
	spawn_along_curve(hand_size)

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

func spawn_along_curve(count: int) -> void:
	var spawn_distance = carddist_offset*Card.width*cardscale
	var curve: Curve2D = spawnPath.curve
	#var count = hand.size()
	if curve.get_baked_points().size() == 0:
		return

	# 1. Calculate the starting horizontal offset relative to the Path2D's local origin
	var start_offset_x: float = (count - 1) * spawn_distance / 2.0

	for i in range(count):
		# 2. Determine the target X coordinate for this instance
		var target_x: float = (i * spawn_distance) - start_offset_x
		
		# 3. Find the matching Y coordinate on the curve for this target X
		var target_y: float = get_y_at_x(curve, target_x)
		
		# 4. Instance and position the object
		var instance = Card.make_card(false)
		instance.position = Vector2(target_x, target_y)
		instance.scale = Vector2(cardscale, cardscale)
		add_child(instance)
		
# Helper function to sample the curve's Y value at a specific X coordinate
func get_y_at_x(curve: Curve2D, target_x: float) -> float:
	var baked_points = curve.get_baked_points()
	
	# If the requested X is completely to the left of the curve, clamp to the start
	if target_x <= baked_points[0].x:
		return baked_points[0].y
		
	# If the requested X is completely to the right, clamp to the end
	if target_x >= baked_points[-1].x:
		return baked_points[-1].y

	# Search through the baked points of the curve to find the segment containing target_x
	for i in range(baked_points.size() - 1):
		var p1 = baked_points[i]
		var p2 = baked_points[i + 1]
		
		if p1.x <= target_x and target_x <= p2.x:
			# Linear interpolation: find where target_x sits between p1.x and p2.x
			var t: float = (target_x - p1.x) / (p2.x - p1.x)
			# Return the interpolated Y value
			return lerp(p1.y, p2.y, t)
			
	return 0.0

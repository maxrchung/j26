class_name OtherPlayer extends Node

var player_id: String
var player_count: int
var player_name: String
var hand_size: int

var useLegacyCardFan: bool = false
const PLAYING_CARD_SCENE = preload("res://objects/PlayingCard.tscn")

@onready var label: RichTextLabel = $RichTextLabel
@onready var spawnPath: Path2D = $SpawnPath
@onready var bidView: BidView = $BidView

## CARD FAN CONSTANTS
# card separation distance and scale
var carddist_offset: float = 0.8 # ratio of card width apart that cards spawn
var cardscale: float = 0.3 
# maximum rotation angle for card fan
var max_card_rotation_deg: float = 15.0 
var max_card_rotation_rad: float = deg_to_rad(max_card_rotation_deg)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# init player id text?
	label.text = player_name
	bidView.OwnerID = player_id
	if (useLegacyCardFan): 
		spawn_along_curve(hand_size)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_hand_size() -> int:
	return hand_size
	
func reveal_hand() -> void:
	pass

# render hand spread?
func render_hand() -> void:
	var curve = spawnPath.curve
	var total_length = curve.get_baked_length()

func spawn_along_curve(count: int) -> void:
	var curve: Curve2D = spawnPath.curve
	if curve.get_baked_points().size() == 0:
		return

	for i in range(count):
		var instance: PlayingCard = PLAYING_CARD_SCENE.instantiate()
		instance.face_up = false

		var spawn_distance = carddist_offset * instance.custom_minimum_size.x * cardscale
	
		# 1. Calculate the starting horizontal offset relative to the Path2D's local origin
		var start_offset_x: float = (count - 1) * spawn_distance / 2.0
		# 2. Determine the target X coordinate for this instance
		var target_x: float = (i * spawn_distance) - start_offset_x
		
		# 3. Find the matching Y coordinate on the curve for this target X
		var target_y: float = get_y_at_x(curve, target_x)
		
		# 4. Calculate rotation factor from -1.0 (leftmost) to 1.0 (rightmost)
		var rotation_factor: float = 0.0
		if count > 1:
			rotation_factor = (i / (count - 1.0)) * 2.0 - 1.0
		
		var target_rotation: float = rotation_factor * max_card_rotation_rad
		
		# --- NEW PIVOT FIX CODE ---
		# 1. Determine the center of the card in local space, accounting for scale
		var card_center_local: Vector2 = (instance.custom_minimum_size * cardscale) / 2.0
		
		# 2. Rotate that center vector by our target rotation
		var rotated_center: Vector2 = card_center_local.rotated(target_rotation)
		
		# 3. Calculate the top-left position by subtracting the rotated center 
		#    from our intended curve center position (target_x, target_y)
		var target_center: Vector2 = Vector2(target_x, target_y)
		var top_left_position: Vector2 = target_center - rotated_center
		# --------------------------
		
		# 5. Position, scale, and rotate the object
		instance.position = top_left_position
		instance.scale = Vector2(cardscale, cardscale)
		instance.rotation = target_rotation 
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

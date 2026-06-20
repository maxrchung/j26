extends Node

#const PLAYER_SCENE = preload("res://scenes/Player.tscn")
const OTHER_PLAYER_SCENE = preload("res://scenes/OtherPlayer.tscn")

@export var spawn_path: Path2D

var game_state: GameState
#@onready var player: Player = $Player

@export var NUM_PLAYERS: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_game(NUM_PLAYERS)


func _init_game(num_players: int) -> void:
	#player.player_id = register_self()
	game_state = GameState.new()
	game_state.player_count = num_players
	_create_other_players()
	
func _create_other_players() -> void:
	var other_player_ids = get_lobby()
		
	var curve: Curve2D = spawn_path.curve
	var total_length: float = curve.get_baked_length()

	var n_other_players = game_state.player_count - 1
	for i in n_other_players:
		# Calculate the proportional distance along the path (0.0 to 1.0)
		var progress_ratio: float = float(i) / float(n_other_players - 1)

		# Sample the curve length using the ratio
		var offset: float = progress_ratio * total_length

		# Get the exact global position on the path
		var spawn_pos: Vector2 = spawn_path.global_transform * curve.sample_baked(offset)

		var instance: OtherPlayer = OTHER_PLAYER_SCENE.instantiate()
		instance.global_position = spawn_pos
		instance.player_id = other_player_ids[i]
		instance.hand_size = randi_range(1, 6)
		
		game_state.other_players.append(instance)
		add_child(instance)
		
# Client Stubs
# Register self, get player ID 
func register_self() -> int:
	return 1


# Get player ID of other players in the lobby
func get_lobby() -> Array[int]:
	var result: Array[int] = []
	result.resize(NUM_PLAYERS-1)
	
	for i in range(NUM_PLAYERS-1):
		result[i] = randi_range(2, 30)
		
	return result

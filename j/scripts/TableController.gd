class_name TableController extends Node

const OTHER_PLAYER_SCENE = preload("res://scenes/OtherPlayer.tscn")

@onready var spawn_path: Path2D = $SpawnPath

@export var debug_lobby_size: int = 2
var debug_players: Array[DebugPlayer] = []

var game_state: GameState
var self_id: String

class DebugPlayer:
	var id: String = str(randi_range(1000, 9999))
	var name: String = "player"
	#var card_count = randi_range(1,6)
	
func _ready() -> void:
	ServerConnection.game_started.connect(_init_table)
	if name == "DebugTable":
		for i in debug_lobby_size:
			debug_players.append(DebugPlayer.new())
		_init_table(debug_players)
		
func _init_table(players) -> void:
	print("init table called")
	game_state = GameState.new()
	game_state.player_count = players.size()
	_create_other_players(players)

func update_player_hands(player_hands) -> void:
	player_hands
	for other_player in game_state.other_players:
		pass
	
func _create_other_players(players) -> void:
	
	var curve: Curve2D = spawn_path.curve
	var total_length: float = curve.get_baked_length()
	
	var i_other = 0
	var n_other_players = game_state.player_count - 1
	for player in players:
		if (player.id == ServerConnection.CurrentPlayerID): continue # don't count self
		
		var progress_ratio: float = _calculate_progress_ratio(i_other, n_other_players)

		# Sample the curve length using the ratio
		var offset: float = progress_ratio * total_length

		# Get the exact global position on the path
		var spawn_pos: Vector2 = spawn_path.global_transform * curve.sample_baked(offset)

		var instance: OtherPlayer = OTHER_PLAYER_SCENE.instantiate()
		instance.global_position = spawn_pos
		instance.player_id = player.id
		instance.player_name = player.name
		
		game_state.other_players[player.id] = instance
		add_child(instance)
		i_other += 1

# Calculate the proportional distance along the path (0.0 to 1.0)
func _calculate_progress_ratio(player_idx: int, n_other: int) -> float:
	# Hard code distances for low player ct
	if n_other == 1: return 0.5 
	if n_other == 2: return [0.2, 0.8][player_idx]
	if n_other == 3: return [0.1, 0.5, 0.9][player_idx]
	return float(player_idx) / float(n_other - 1)

class_name Field extends Node2D

signal goal_scored(team)

const PUFFERFISH_SCENE: PackedScene = preload("res://objects/pufferfish/pufferfish.tscn")

@onready var _players_root: Node2D = $Players
@onready var _ball: Ball = $Ball
@onready var _map: Map = $Map

var _players: Array[Pufferfish] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_add_existing_players()

	# connect signals
	_map.left_scored.connect(_on_left_goal_scored)
	_map.right_scored.connect(_on_right_goal_scored)

func _create_players(players_settings: Array[Pufferfish.PlayerSettings]) -> void:
	for p_settings in players_settings:
		var pufferfish: Pufferfish = PUFFERFISH_SCENE.instantiate()
		pufferfish.settings = p_settings
		_players.append(pufferfish)
		_players_root.add_child(pufferfish)

#
# Public functions
#

func new_round() -> void:
	# reset ball
	_ball.force_position(_map.get_ball_starting_position())

	# get spawn points
	var left_player_positions = _map.get_player_starting_positions(Game.Team.LEFT)
	var right_player_positions = _map.get_player_starting_positions(Game.Team.RIGHT)

	# set spawn points for players
	# TODO: select random points for spawns
	var l = 0
	var r = 0
	for p in _players:
		var pos: Vector3
		if p.settings.team == Game.Team.LEFT:
			pos = left_player_positions[l]
			l += 1
		else:
			pos = right_player_positions[r]
			r += 1
		p.force_position(Vector2(pos.x, pos.y))
		p.set_orientation(rad_to_deg(pos.z))


func setup(players_settings: Array[Pufferfish.PlayerSettings]) -> void:
	_ball.force_position(_map.get_ball_starting_position())
	_create_players(players_settings)
	#TODO: wait for all the players to be ready

#
# Signal functions
#

func _on_left_goal_scored() -> void:
	goal_scored.emit(Game.Team.LEFT)

func _on_right_goal_scored() -> void:
	goal_scored.emit(Game.Team.RIGHT)

#
# Editor functions
#

## Add any existing players that were added in the editor
func _add_existing_players() -> void:
	for p in _players_root.get_children():
		_players.append(p)

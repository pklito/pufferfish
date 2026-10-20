class_name Field extends Node2D

signal goal_scored(team: Game.Team)

const PUFFERFISH_SCENE: PackedScene = preload("res://objects/pufferfish/pufferfish.tscn")

@onready var _players_root: Node2D = $Players
@onready var _ball: Ball = $Ball
# TODO: get map id in Game.GameSettings and instantiate the map
@onready var _map: Map = $Map

var _players: Array[Pufferfish] = []


func _ready() -> void:
	_add_existing_players()

	# connect signals
	_map.left_scored.connect(_on_left_goal_scored)
	_map.right_scored.connect(_on_right_goal_scored)

#
# Public functions
#

## Set ball and player positions to the kickoff
func set_kickoff() -> void:
	# reset ball
	_ball.force_position(_map.get_ball_starting_position())

	# get spawn points (sorted by distance to ball)
	var left_player_positions = _map.get_player_starting_positions(Game.Team.LEFT)
	var right_player_positions = _map.get_player_starting_positions(Game.Team.RIGHT)
	
	# get max team size
	var l_count = 0; var r_count= 0
	for p in _players:
		if p.settings.team == Game.Team.LEFT: l_count += 1
		else: r_count += 1
	var k = max(l_count, r_count); var n = left_player_positions.size()

	# get k (max team size) random sorted subset of indeces
	var indeces = []
	for i in range(n): indeces.append(i)
	indeces.shuffle()
	indeces = indeces.slice(0, k)
	indeces.sort()

	# shuffle the players around
	# TODO: maybe not shuffle idk not a problem
	_players.shuffle()

	# set spawn points for players
	var l = 0
	var r = 0
	for p in _players:
		var pos: Vector3
		if p.settings.team == Game.Team.LEFT:
			pos = left_player_positions[indeces[l]]
			l += 1
		else:
			pos = right_player_positions[indeces[r]]
			r += 1
		p.force_position(Vector2(pos.x, pos.y))
		p.set_orientation(rad_to_deg(pos.z))

func init_players(players_settings: Array[Pufferfish.PlayerSettings]) -> void:
	for p_settings in players_settings:
		var pufferfish: Pufferfish = PUFFERFISH_SCENE.instantiate()
		pufferfish.settings = p_settings
		_players.append(pufferfish)
		_players_root.add_child(pufferfish)
	#TODO: wait for all the players to be ready

func freeze_players() -> void:
	for p in _players_root.get_children():
		p.frozen = true

func unfreeze_players() -> void:
	for p in _players_root.get_children():
		p.frozen = false

func set_player_names_visibility(val: bool) -> void:
	for p in _players:
		p.set_name_visibility(val)

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


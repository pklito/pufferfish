class_name Field extends Node2D

signal goal_scored(team)

const PUFFERFISH_SCENE: PackedScene = preload("res://objects/pufferfish/pufferfish.tscn")

@onready var _map: Map = $Map
@onready var _ball: Ball = $Ball

#TODO: instantiate players yadayada
@onready var p1 = $Players/Player1
@onready var p2 = $Players/Player2



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_map.left_scored.connect(_on_left_goal_scored)
	_map.right_scored.connect(_on_right_goal_scored)

func new_round() -> void:
	_ball.force_position(_map.get_ball_starting_position())
	var left_player_positions = _map.get_player_starting_positions(true, 1)
	var right_player_positions = _map.get_player_starting_positions(false, 1)

	# TODO: per player yadayada teams yadaydadad
	var p1_pos = left_player_positions[0]
	var p2_pos = right_player_positions[0]
	p1.force_position(Vector2(p1_pos[0], p1_pos[1]))
	p1.set_orientation(p1_pos[2])
	p2.force_position(Vector2(p2_pos[0], p2_pos[1]))
	p2.set_orientation(p2_pos[2])

func setup() -> void:
	new_round()

func _on_left_goal_scored() -> void:
	goal_scored.emit(0)

func _on_right_goal_scored() -> void:
	goal_scored.emit(1)

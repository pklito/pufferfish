class_name Field extends Node2D

signal goal_scored(team)


@export var _ball: Ball

#TODO: instantiate players yadayada
@onready var p1 = $Players/Player1
@onready var p2 = $Players/Player2

@export var _player_starting_distance: float = 300.0
@export var _ball_starting_pos: Vector2 = Vector2.ZERO


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func new_round() -> void:
	_ball.force_position(_ball_starting_pos)
	p1.force_position(Vector2(-_player_starting_distance, 0.0))
	p1.set_orientation(90)
	p2.force_position(Vector2(_player_starting_distance, 0.0))
	p2.set_orientation(-90)

func setup() -> void:
	new_round()

func _on_left_goal_body_entered(_body: Node2D) -> void:
	goal_scored.emit(0)

func _on_right_goal_body_entered(_body: Node2D) -> void:
	goal_scored.emit(1)

extends Node2D

signal goal_scored(team)


@export var ball: RigidBody2D

#TODO: instantiate players yadayada
@onready var p1 = $Players/Player1
@onready var p2 = $Players/Player2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _new_round() -> void:
	#TODO: set ball position to center and players to their starting positions and rotations
	pass

func setup() -> void:
	_new_round()

func _on_left_goal_body_entered(body: Node2D) -> void:
	_new_round()


func _on_right_goal_body_entered(body: Node2D) -> void:
	_new_round()

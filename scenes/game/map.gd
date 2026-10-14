@tool
extends Node2D

const SPRITE_SIZE := 256.0

@export_range(0.1, 5000.0) var width: float = 1400.0:
	set(value):
		width = value
		if Engine.is_editor_hint() and is_node_ready(): _update_sizes()
@export_range(0.1, 4000.0) var height: float = 1000.0:
	set(value):
		height = value
		if Engine.is_editor_hint() and is_node_ready(): _update_sizes()
@export_range(0.0, 5000.0) var goal_size: float = 500.0:
	set(value):
		goal_size = value
		if Engine.is_editor_hint() and is_node_ready(): _update_sizes()
@export_range(0.1, 1000.0) var wall_width: float = 50.0:
	set(value):
		wall_width = value
		if Engine.is_editor_hint() and is_node_ready(): _update_sizes()

@onready var up: StaticBody2D = $Up
@onready var down: StaticBody2D = $Down
@onready var left_up: StaticBody2D = $LeftUp
@onready var left_down: StaticBody2D = $LeftDown
@onready var right_up: StaticBody2D = $RightUp
@onready var right_down: StaticBody2D = $RightDown

@onready var left_blocker: StaticBody2D = $LeftBlocker
@onready var right_blocker: StaticBody2D = $RightBlocker
@onready var left_goal: Area2D = $LeftGoal
@onready var right_goal: Area2D = $RightGoal


func _ready() -> void:
	_update_sizes()

func _update_sizes() -> void:
	up.get_child(0).shape.size = Vector2(width+wall_width*2.0, wall_width)
	up.get_child(1).scale = Vector2((width+wall_width*2.0)/SPRITE_SIZE, wall_width/SPRITE_SIZE)
	up.position = Vector2(0, -(height+wall_width)/2.0)

	down.get_child(0).shape.size = Vector2(width+wall_width*2.0, wall_width)
	down.get_child(1).scale = Vector2((width+wall_width*2.0)/SPRITE_SIZE, wall_width/SPRITE_SIZE)
	down.position = Vector2(0, (height+wall_width)/2.0)

	var side_size = (height-goal_size)/2.0
	left_up.get_child(0).shape.size = Vector2(wall_width, side_size)
	left_up.get_child(1).scale = Vector2(wall_width/SPRITE_SIZE, side_size/SPRITE_SIZE)
	left_up.position = Vector2(-(width+wall_width)/2.0, -(side_size+goal_size)/2.0)
	left_down.get_child(0).shape.size = Vector2(wall_width, side_size)
	left_down.get_child(1).scale = Vector2(wall_width/SPRITE_SIZE, side_size/SPRITE_SIZE)
	left_down.position = Vector2(-(width+wall_width)/2.0, (side_size+goal_size)/2.0)

	right_up.get_child(0).shape.size = Vector2(wall_width, side_size)
	right_up.get_child(1).scale = Vector2(wall_width/SPRITE_SIZE, side_size/SPRITE_SIZE)
	right_up.position = Vector2((width+wall_width)/2.0, -(side_size+goal_size)/2.0)
	right_down.get_child(0).shape.size = Vector2(wall_width, side_size)
	right_down.get_child(1).scale = Vector2(wall_width/SPRITE_SIZE, side_size/SPRITE_SIZE)
	right_down.position = Vector2((width+wall_width)/2.0, (side_size+goal_size)/2.0)

	left_blocker.position = Vector2(-(width/2.0 + wall_width), 0.0)
	left_goal.position = Vector2(-(width/2.0 + wall_width*1.5), 0.0)
	right_blocker.position = Vector2((width/2.0 + wall_width), 0.0)
	right_goal.position = Vector2((width/2.0 + wall_width*1.5), 0.0)


@tool
class_name Map extends Node2D

signal left_scored
signal right_scored

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
@export_range(0.0, 1000.0) var corner_width: float = 50.0:
	set(value):
		corner_width = value
		if Engine.is_editor_hint() and is_node_ready(): _update_sizes()
@export_range(0.02, PI/2.0-0.02) var corner_angle: float = PI/4.0:
	set(value):
		corner_angle = value
		if Engine.is_editor_hint() and is_node_ready(): _update_sizes()

@onready var _upper_wall: StaticBody2D = $UpperWall
@onready var _lower_wall: StaticBody2D = $LowerWall

@onready var left_blocker: StaticBody2D = $LeftBlocker
@onready var right_blocker: StaticBody2D = $RightBlocker
@onready var left_goal: Area2D = $LeftGoal
@onready var right_goal: Area2D = $RightGoal

@onready var _ball_marker: Marker2D = $BallMarker


func _ready() -> void:
	left_goal.body_entered.connect(_on_left_goal_body_enter)
	right_goal.body_entered.connect(_on_right_goal_body_enter)
	_update_sizes()

func _update_wall_size(wall: StaticBody2D, up: bool) -> void:
	var flip = -1.0 if up else 1.0
	var points := PackedVector2Array()

	var corner_point = Vector2(width/2.0, height/2.0)
	var pre_corner = Vector2(corner_point[0] - corner_width/cos(corner_angle), corner_point[1] * flip)
	var post_corner = Vector2(corner_point[0], (corner_point[1] - corner_width/sin(corner_angle)) * flip)
	points.append(pre_corner)
	points.append(post_corner)
	points.append(Vector2(width/2.0, goal_size/2.0 * flip))
	points.append(Vector2(width/2.0 + wall_width, goal_size/2.0 * flip))
	points.append(Vector2(width/2.0 + wall_width, (height/2.0 + wall_width) * flip))

	points.append(Vector2(-(width/2.0 + wall_width), (height/2.0 + wall_width)* flip))
	points.append(Vector2(-(width/2.0 + wall_width), goal_size/2.0 * flip))
	points.append(Vector2(-width/2.0, goal_size/2.0 * flip))
	points.append(Vector2(-post_corner[0], post_corner[1]))
	points.append(Vector2(-pre_corner[0], pre_corner[1]))

	wall.get_child(0).polygon = points
	wall.get_child(1).polygon = points

func _update_sizes() -> void:

	_update_wall_size(_upper_wall, true)
	_update_wall_size(_lower_wall, false)

	left_blocker.position = Vector2(-(width/2.0 + wall_width), 0.0)
	left_goal.position = Vector2(-(width/2.0 + wall_width*1.5), 0.0)
	right_blocker.position = Vector2((width/2.0 + wall_width), 0.0)
	right_goal.position = Vector2((width/2.0 + wall_width*1.5), 0.0)

func _on_left_goal_body_enter(body: RigidBody2D) -> void:
	if body is Ball: left_scored.emit()

func _on_right_goal_body_enter(body: RigidBody2D) -> void:
	if body is Ball: right_scored.emit()

## Returns the starting position of the ball in the map
func get_ball_starting_position() -> Vector2:
	return _ball_marker.position

## Args: [param left_team] true if getting positions for left team, [param team_count] amount
## of players per team.[br]
## Returns: [Array] of [Vector3] per player with (x, y, r) where x, y is the position
## and r the orientation in radians, or an empty array if missing data
func get_player_starting_positions(left_team: bool, team_count: int) -> Array[Vector3]:
	var offset = 300.0
	if left_team: return [Vector3(-offset, 0.0, 90.0)]
	return [Vector3(offset, 0.0, -90.0)]


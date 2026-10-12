extends Node

const WALL_SCENE: PackedScene = preload("res://objects/wallnew.tscn")
const BALL_SCENE: PackedScene = preload("res://objects/ball.tscn")

const DEFAULT_FIELD_SIZE := Vector2(1152, 600.0)
@export var field_size_mult = 1.0


@onready var walls: Node2D = $World/Walls
@onready var camera = $World/Camera



func add_wall(wall_position: Vector2, wall_rotation: float, wall_length: float) -> void:
	var wall := WALL_SCENE.instantiate() as StaticBody2D
	wall.position = wall_position
	wall.rotation = wall_rotation
	var visual = wall.get_node("MeshInstance2D")
	visual.mesh.size = Vector2(wall_length, visual.mesh.size.y)
	var collider = wall.get_node("CollisionShape2D")
	collider.shape.size = Vector2(wall_length, collider.shape.size.y)
	walls.add_child(wall)

func setup_field() -> void:
	var fieldSize = field_size_mult * DEFAULT_FIELD_SIZE
	add_wall(Vector2(fieldSize.x / 2.0, 0.0), 0.0, fieldSize.x)
	add_wall(Vector2(fieldSize.x / 2.0, fieldSize.y), 0.0, fieldSize.x)
	add_wall(Vector2(0.0, fieldSize.y / 2.0), PI / 2.0, fieldSize.y)
	add_wall(Vector2(fieldSize.x, fieldSize.y / 2.0), PI / 2.0, fieldSize.y)
	camera.position = Vector2(fieldSize.x/2, fieldSize.y/2)
	camera.zoom = Vector2(1.0/field_size_mult, 1.0/field_size_mult)
	var ball := BALL_SCENE.instantiate() as RigidBody2D
	ball.position = Vector2(fieldSize.x * 0.75, fieldSize.y / 2.0)
	$World.add_child(ball)


func _ready() -> void:
	setup_field()


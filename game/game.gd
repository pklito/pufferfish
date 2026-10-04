extends Node


const defaultFieldSize := Vector2(1152, 600.0)
@export var fieldSizeMult = 1.0
var fieldSize


var wallScene: PackedScene = preload("res://game/wallnew.tscn")
var ballScene: PackedScene = preload("res://game/ball.tscn")

@onready var walls: Node2D = $Walls
@onready var Camera = $Camera



func addWall(wallPosition: Vector2, wallRotation: float, wallLength: float) -> void:
	var wall := wallScene.instantiate() as StaticBody2D
	wall.position = wallPosition
	wall.rotation = wallRotation
	var visual = wall.get_node("MeshInstance2D")
	visual.mesh.size = Vector2(wallLength, visual.mesh.size.y)
	var collider = wall.get_node("CollisionShape2D")
	collider.shape.size = Vector2(wallLength, collider.shape.size.y)
	walls.add_child(wall)

func setupField() -> void:
	fieldSize = fieldSizeMult * defaultFieldSize
	addWall(Vector2(fieldSize.x / 2.0, 0.0), 0.0, fieldSize.x)
	addWall(Vector2(fieldSize.x / 2.0, fieldSize.y), 0.0, fieldSize.x)
	addWall(Vector2(0.0, fieldSize.y / 2.0), PI / 2.0, fieldSize.y)
	addWall(Vector2(fieldSize.x, fieldSize.y / 2.0), PI / 2.0, fieldSize.y)
	Camera.position = Vector2(fieldSize.x/2, fieldSize.y/2)
	Camera.zoom = Vector2(1.0/fieldSizeMult, 1.0/fieldSizeMult)
	var ball := ballScene.instantiate() as RigidBody2D
	ball.position = Vector2(fieldSize.x * 0.75, fieldSize.y / 2.0)
	add_child(ball)
	
	

func _ready() -> void:
	setupField()
	

extends Node


@export var fieldSize := Vector2(1152, 600.0)

var wallScene: PackedScene = preload("res://game/wallnew.tscn")

@onready var walls: Node2D = $Walls

func addWall(wallPosition: Vector2, wallRotation: float, wallLength: float) -> void:
	var wall := wallScene.instantiate() as StaticBody2D
	wall.position = wallPosition
	wall.rotation = wallRotation
	var visual = wall.get_node("MeshInstance2D")
	visual.mesh.size = Vector2(wallLength, visual.mesh.size.y)
	var collider = wall.get_node("CollisionShape2D")
	collider.shape.size = Vector2(wallLength, collider.shape.size.y)
	walls.add_child(wall)


func _ready() -> void:
	addWall(Vector2(fieldSize.x / 2.0, 0.0), 0.0, fieldSize.x)
	addWall(Vector2(fieldSize.x / 2.0, fieldSize.y), 0.0, fieldSize.x)
	addWall(Vector2(0.0, fieldSize.y / 2.0), PI / 2.0, fieldSize.y)
	addWall(Vector2(fieldSize.x, fieldSize.y / 2.0), PI / 2.0, fieldSize.y)

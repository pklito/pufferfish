extends Node


@export var fieldSize := Vector2(1152, 600.0)

var wallScene: PackedScene = preload("res://game/wallnew.tscn")

@onready var walls: Node2D = $Walls

func addWall(wallPosition: Vector2, wallRotation: float) -> void:
	var wall := wallScene.instantiate() as StaticBody2D
	wall.position = wallPosition
	wall.rotation = wallRotation
	walls.add_child(wall)


func _ready() -> void:
	addWall(Vector2(fieldSize.x / 2.0, 0.0), 0.0)
	addWall(Vector2(fieldSize.x / 2.0, fieldSize.y), 0.0)
	addWall(Vector2(0.0, fieldSize.y / 2.0), PI / 2.0)
	addWall(Vector2(fieldSize.x, fieldSize.y / 2.0), PI / 2.0)

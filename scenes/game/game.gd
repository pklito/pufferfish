extends Node

@export var field: Field

func _ready() -> void:
	field.setup()

func _on_field_goal_scored(_team: Variant) -> void:
	print("score yippe hooray")
	field.new_round()


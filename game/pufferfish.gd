extends Node

@export var amount : int = 20
@export var targetCore : Node2D
var sbnode : PackedScene = preload("res://game/SoftBodyNode.tscn")
# Called when the node enters the scene tree for the first time.

var listPoints := []

func _ready() -> void:
	for a in targetCore.get_children():
		a.scale = Vector2(0.2,0.2)
	for i in range(amount):
		var child : RigidBody2D = sbnode.instantiate()
		add_child(child)
		listPoints.append(child)
		child.global_position = targetCore.global_position + Vector2(0,50).rotated(6.28 * i / amount)
		for a in child.get_children():
			a.scale = Vector2(0.1,0.1)
	
	for i in range(listPoints.size()):
		for j in range(i, listPoints.size()):
			add_child(createJoint(listPoints[i],listPoints[j]))
	
	
	

func createJoint(a : Node2D, b:Node2D, stiffness = 64.0, damping = 10.0) -> DampedSpringJoint2D:
	var joint = RapierDampedSpringJoint2D.new()
	joint.global_position = a.global_position
	var delta = b.global_position - a.global_position
	joint.length = delta.length()
	joint.node_a = a.get_path()
	joint.node_b = b.get_path()
	joint.global_rotation = atan2(-delta.x,delta.y)
	joint.stiffness = stiffness
	joint.damping = damping
	joint.rest_length = joint.length
	return joint

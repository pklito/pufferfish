extends Node

@export var amount : int = 20
@export var targetCore : Node2D
var sbnode : PackedScene = preload("res://game/SoftBodyNode.tscn")
# Called when the node enters the scene tree for the first time.

var listPoints := []
var listJoints := []
var listRestingDists := []


func _ready() -> void:
	for a in targetCore.get_children():
		a.scale = Vector2(0.2,0.2)
	for i in range(amount):
		var child : RigidBody2D = sbnode.instantiate()
		add_child(child)
		listPoints.append(child)
		child.global_position = targetCore.global_position + Vector2(0,40).rotated(6.28 * i / amount)
		for a in child.get_children():
			a.scale = Vector2(0.2,0.2)
	
	for i in range(listPoints.size()):
		for j in range(i, listPoints.size()):
			var joint = createJoint(listPoints[i],listPoints[j], 240, 0.3)
			add_child(joint)
			listJoints.append(joint)
			listRestingDists.append(joint.rest_length)
	
	
	

func createJoint(a : Node2D, b:Node2D, stiffness = 340.0, damping = 0.2) -> DampedSpringJoint2D:
	var joint = DampedSpringJoint2D.new()
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

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton):
		for i in range(listJoints.size()):
			var joint = listJoints[i]
			joint.rest_length = listRestingDists[i] * (0.2 if event.pressed else 1.0) 

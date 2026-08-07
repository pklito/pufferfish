extends Node

@export var amount : int = 20
@export var targetCore : PhysicsBody2D
var sbnode : PackedScene = preload("res://game/SoftBodyNode.tscn")
# Called when the node enters the scene tree for the first time.

var listRing := []
var listRadial := []

@export var ringDistance := 16.0
@export var radialDistance := 50.0

func _ready() -> void:
	for a in targetCore.get_children():
		a.scale = Vector2(0.2,0.2)
	var last_point : RigidBody2D = null
	var first_point : RigidBody2D = null
	for i in range(amount):
		var child : RigidBody2D = sbnode.instantiate()
		add_child(child)
		child.global_position = targetCore.global_position + Vector2(0,50).rotated(6.28 * i / amount)
		for a in child.get_children():
			a.scale = Vector2(0.1,0.1)
		var joint = createJoint(targetCore, child)
		listRadial.append(joint)
		add_child(joint)
		if(last_point):
			var j2 = createJoint(child,last_point, 1000)
			add_child(j2)
			listRing.append(j2)
		else:
			first_point = child
		if i == amount - 1:
			var j2 = createJoint(first_point, child, 1000)
			add_child(j2)
			listRing.append(j2)
			add_child(j2)
			
		last_point = child
			
	

func createJoint(a : Node2D, b:Node2D, stiffness = 64.0, damping = 0.0) -> DampedSpringJoint2D:
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for a : DampedSpringJoint2D in listRadial:
		a.rest_length = radialDistance
	
	for a : DampedSpringJoint2D in listRing:
		a.rest_length = ringDistance
	pass

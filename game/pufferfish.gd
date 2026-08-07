extends Node

@export var amount : int = 20
@export var targetCore : PhysicsBody2D
var sbnode : PackedScene = preload("res://game/SoftBodyNode.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for a in targetCore.get_children():
		a.scale = Vector2(0.2,0.2)
	for i in range(amount):
		var child : RigidBody2D = sbnode.instantiate()
		add_child(child)
		child.global_position = targetCore.global_position + Vector2(50,0).rotated(6.28 * i / amount)
		for a in child.get_children():
			a.scale = Vector2(0.1,0.1)
		var joint = DampedSpringJoint2D.new()
		joint.length = 50.0
		joint.global_position = targetCore.global_position
		joint.rotation = 6.28 * i / amount
		joint.node_b = child.get_path()
		joint.node_a = targetCore.get_path()
		joint.stiffness = 64.0
		joint.rest_length = 50.0
		joint.damping = 4.0
		add_child(joint)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

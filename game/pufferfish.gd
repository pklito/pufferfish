extends Node

# Amount of rings on the perimeter of the pufferfish
@export var amount : int = 20
@export var radius : float = 40
@export var nodeSize: float = 0.2
@export var targetCore : Node2D
@export var visualPolygon : Polygon2D
@export var visualRim : Line2D

var sbnode : PackedScene = preload("res://game/SoftBodyNode.tscn")
# Called when the node enters the scene tree for the first time.

var listPoints := []
var listJoints := []
var listRestingDists := []

func _ready() -> void:
	# What is the purpose of this?
	for a in targetCore.get_children():
		a.scale = Vector2(0.2,0.2)
	for i in range(amount):
		var child : RigidBody2D = sbnode.instantiate()
		add_child(child)
		listPoints.append(child)
		child.global_position = targetCore.global_position + Vector2(0,radius).rotated(2 * PI * i / amount)
		for a in child.get_children():
			a.scale = Vector2(nodeSize, nodeSize)
	
	for i in range(listPoints.size()):
		for j in range(i+1, listPoints.size()):
			var joint = createJoint(listPoints[i],listPoints[j])
			add_child(joint)
			listJoints.append(joint)
			listRestingDists.append(joint.rest_length)
	
	
	

func createJoint(a : Node2D, b:Node2D, stiffness = 700, damping = 0.6) -> DampedSpringJoint2D:
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

var scaleTween : Tween
func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton):
		if(scaleTween != null):
			scaleTween.stop()
		scaleTween = get_tree().create_tween()
		if (event.pressed):
			scaleTween.tween_method(setScale, 1.0, 0.4, 0.15).set_trans(Tween.TRANS_LINEAR)
		else:
			scaleTween.tween_method(setScale, 0.4, 1.0, 0.05).set_trans(Tween.TRANS_LINEAR)
		scaleTween.play()
	
	

func setScale(scale : float):
	for i in range(listJoints.size()):
		var joint = listJoints[i]
		joint.rest_length = listRestingDists[i] * scale
		
func updateRim() -> void:
	var points = []
	for a in listPoints:
		points.append(a.global_position)
	visualPolygon.polygon = points
	visualRim.points = points

func _process(delta: float) -> void:
	updateRim()
	var dir = Input.get_vector("left", "right", "up", "down")
	var force_angle = dir.angle_to(Vector2(0,1))
	print(force_angle)
	
	
	
	

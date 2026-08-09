extends Node2D

@export_category("Connections")
@export var visualPolygon : Polygon2D
@export var visualRim : Line2D

@export_category("Ball config")
@export var nodeCount : int = 20	##Amount of softBodyNodes the ball has
@export var radius : float = 50		##Ball total radius, including node collision sizes
@export var nodeRadius: float = 10  ##Node collider radii
@export var ballMass : float = 20
@export var stiffnessCurve : Curve = Curve.new()
@export var dampingCurve : Curve = Curve.new()


@export_category("Shrink expand")
@export var shrinkTime : float = 0.15
@export var expandTime : float = 0.05
@export_range(0.1,1.0,0.01) var shrinkFactor : float = 0.4 


var sbnode : PackedScene = preload("res://game/SoftBodyNode.tscn")
# Called when the node enters the scene tree for the first time.

var listPoints := []
var listJoints := []
var listRestingDists := []

func _ready() -> void:
	# What is the purpose of this?
	for i in range(nodeCount):
		var child : RigidBody2D = sbnode.instantiate()
		child.mass = ballMass / nodeCount
		add_child(child)
		listPoints.append(child)
		child.global_position = global_position + Vector2(0,radius - nodeRadius).rotated(2 * PI * i / nodeCount)
		for a in child.get_children():
			a.scale = Vector2(nodeRadius/50.0, nodeRadius/50.0)	## In SoftBodyNode.tscn, the radius is 50
	
	for i in range(listPoints.size()):
		for j in range(i+1, listPoints.size()):
			var stiffnessAmount = 0.5 * (listPoints[i].position - listPoints[j].position).length() / (radius - nodeRadius)
			var joint = createJoint(listPoints[i],listPoints[j], stiffnessCurve.sample(stiffnessAmount), dampingCurve.sample(stiffnessAmount))
			add_child(joint)
			listJoints.append(joint)
			listRestingDists.append(joint.rest_length)
	
	
	

func createJoint(a : Node2D, b:Node2D, stiffness : float = 700, damping : float = 0.6) -> DampedSpringJoint2D:
	var joint = DampedSpringJoint2D.new()
	joint.global_position = a.position
	var delta = b.position - a.position
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
			scaleTween.tween_method(setScale, 1.0, shrinkFactor, shrinkTime).set_trans(Tween.TRANS_LINEAR)
		else:
			scaleTween.tween_method(setScale, shrinkFactor, 1.0, expandTime).set_trans(Tween.TRANS_LINEAR)
		scaleTween.play()

func setScale(scale : float):
	for i in range(listJoints.size()):
		var joint = listJoints[i]
		joint.rest_length = listRestingDists[i] * scale

func _process(delta: float) -> void:
	var points = []
	for a in listPoints:
		points.append(a.position)
	visualPolygon.polygon = points
	visualRim.points = points

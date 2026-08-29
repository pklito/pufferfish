extends Node2D

@export_category("Connections")
@export var visualPolygon : Polygon2D
@export var visualRim : Line2D

@export_category("Ball config")
# Keep this even (TODO: make a warning/throw an error if not)
@export var nodeCount : int = 30	##Amount of softBodyNodes the ball has
@export var radius : float = 50		##Ball total radius, including node collision sizes
@export var nodeRadius: float = 10  ##Node collider radii
@export var ballMass : float = 20
@export var stiffnessCurve : Curve = Curve.new()
@export var dampingCurve : Curve = Curve.new()
@export var movementForce: float = 3000
@export var spinTorque: float = 100000


@export_category("Shrink expand")
@export var shrinkTime : float = 0.05
@export var expandTime : float = 0.15
@export_range(0.1,1.0,0.01) var shrinkFactor : float = 0.4 

var orientation : float = 0.0
var previousOrientation : float = orientation
var angularVelocity : float = 0.0

var sbnode : PackedScene = preload("res://game/SoftBodyNode.tscn")
# Called when the node enters the scene tree for the first time.

var listPoints := []
var listJoints := []
var listRestingDists := []
var debugForcePoints := []

# Is this right? Is global position the com of the spawn position
var CoM = global_position
var PreviousCoM = CoM
var CoMVelocity = 0

func _ready() -> void:
	visualRim.width = 2 * nodeRadius
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
		
func updateRim() -> void:
	var points = []
	for a in listPoints:
		points.append(a.position)
	visualPolygon.polygon = points
	visualRim.points = points

func _draw() -> void:
	for point in debugForcePoints:
		draw_arc(point, nodeRadius, 0.0, TAU, 24, Color.RED, 3.0)

func updateCoM() -> void:
	var sumPositions = Vector2.ZERO
	for i in range(nodeCount):
		sumPositions += listPoints[i].position
	CoM = sumPositions/nodeCount
	
	
	
func _physics_process(delta) -> void:
	updateRim()
	updateCoM()
	previousOrientation = orientation
	orientation = (listPoints[0].position - listPoints[nodeCount/2].position).angle_to(Vector2(0,1))
	angularVelocity = (orientation - previousOrientation)/delta
	# DEALING WITH MOVEMENT
	var dir = Input.get_vector("left", "right", "up", "down")
	var force_angle = dir.angle_to(Vector2(0,-1))
	var forcedPointsCount = 4
	var forcedCenterIndex = roundi((-force_angle + orientation)*nodeCount/(2*PI))
	var centerNode = listPoints[wrapi(forcedCenterIndex, 0, nodeCount)]
	var oppositeNode = listPoints[wrapi(forcedCenterIndex + nodeCount/2, 0, nodeCount)]
	var forcePerNode = movementForce * dir / (forcedPointsCount + 1)
	#TODO: MAKE PUSHED POINTS A DIFFERENT COLOR FOR DEBUGGING
	var residualTorque = 0
	debugForcePoints.clear()
	for i in range(0, forcedPointsCount/2 +1):
		if i == 0:
			debugForcePoints.append(listPoints[wrapi(forcedCenterIndex, 0, nodeCount)].position)
			listPoints[wrapi(forcedCenterIndex, 0, nodeCount)].apply_central_force(forcePerNode)
		else:
			var rightNode = listPoints[wrapi(forcedCenterIndex + i, 0, nodeCount)]
			var leftNode = listPoints[wrapi(forcedCenterIndex - i, 0, nodeCount)]
			debugForcePoints.append(rightNode.position)
			debugForcePoints.append(leftNode.position)
			rightNode.apply_central_force(forcePerNode)
			residualTorque += (rightNode.position - CoM).cross(forcePerNode)
			leftNode.apply_central_force(forcePerNode)
			residualTorque += (leftNode.position - CoM).cross(forcePerNode)
	# cancel the torque by applying a spinning force on both sides
	# compromising slight rotation to make sure this extra force is not doing anything
	# to the linear velocity
	var correctingForceSize = residualTorque / (centerNode.position - CoM).length()
	centerNode.apply_central_force(correctingForceSize/2 * (centerNode.position - CoM).normalized().orthogonal())
	oppositeNode.apply_central_force(correctingForceSize/2 * (oppositeNode.position - CoM).normalized().orthogonal())
	
	var roll_input = Input.get_axis("spin_right", "spin_left")
	var appliedRollForce = roll_input * spinTorque / (listPoints[0].position - CoM).length()
	listPoints[0].apply_central_force(appliedRollForce/2 * (listPoints[0].position - CoM).normalized().orthogonal())
	listPoints[nodeCount/2].apply_central_force(appliedRollForce/2 * (listPoints[nodeCount/2].position - CoM).normalized().orthogonal())
	
	
	
	#TODO: add backwards forces for squishing
	#TODO: ADD A ROLL MOVMENT OPTION THIS CAN BE REALLY COOL
	#TODO: Strong force until some velocity and then only the orthogonal component affects the movement
	#TODO: Think about how we want the movement to be. We could have an opposite force apply
	# twice or more times the usual strength. I kind of like the idea of no speed cap (the physics engine is probably
	# applying some sort of damping in any case). We can have a brake button for the spin
	print(angularVelocity)
	queue_redraw()
	
		
	
	
	
	
	
	

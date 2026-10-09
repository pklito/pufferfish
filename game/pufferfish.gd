extends Node2D


# Debugging variables

# drawing stuff (right now just the nodes that are being pushed)
var draw_on = false

@export_category("Connections")
@export var visualPolygon : Polygon2D
@export var visualRim : Line2D

@export_category("Ball config")
# Keep this even (TODO: make a warning/throw an error if not)
@export var nodeCount : int = 30	##Amount of softBodyNodes the ball has
@export var radius : float = 50		##Ball total radius, including node collision sizes
@export var nodeRadius: float = 10  ##Node collider radii
@export var ballMass : float = 10
@export var stiffnessCurve : Curve = Curve.new()
@export var dampingCurve : Curve = Curve.new()
@export var movementForce: float = 5000
@export var spinTorque: float = 100000
@export var squishForce: float = 30000
@export var spinDamping: float = 10000
@export var shrinkSpeed: float = 2.2
@export var expandSpeed: float = 2.2


@export_category("Shrink expand")
@export var shrinkTime : float = 0.05
@export var expandTime : float = 0.15
@export_range(0.1,1.0,0.01) var shrinkFactor : float = 0.4 

var orientation : float = 0.0
var previousOrientation : float = orientation
var angularVelocity : float = 0.0

var sbnode : PackedScene = preload("res://game/SoftBodyNode.tscn")
var Arrow : PackedScene = preload("res://game/arrow.tscn")
# Called when the node enters the scene tree for the first time.

var listPoints := []
var listJoints := []
var listRestingDists := []
var debugForcePoints := []
var arrow

# Is this right? Is global position the com of the spawn position
var CoM = global_position
var PreviousCoM = CoM
var CoMVelocity = 0

var fishSize = 1
var maxfishSize = 1.3
var minfishSize = 0.4

var I = updateI()
var L = angularVelocity * I

var flipHapenning : bool = false
var rotationSinceFlip : float = 0
var flipTimeRemaining : float = 0
@export var flipTime : float = 0.5
@export var flipStopThreshold : float = 0.05

var explosionHapenning : bool
var timeSinceExplosions : float

# If the angular momentum is smaller than this, apply damping
@export var smallL = 300 * ballMass

func updateI() -> float:
	"""
	Calculates the moment of inertia of the fish
	"""
	var Inertia = 0
	for p in listPoints:
		Inertia += p.mass * (p.position - CoM).length()**2
	I  = Inertia
	return Inertia
		
		

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
			
	arrow = Arrow.instantiate()
	add_child(arrow)
	
	
	

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
var pushAmount: float = 0.0

"""
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
"""
	

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

# for debugging which nodes are being pushed
func _draw() -> void:
	if draw_on:
		for point in debugForcePoints:
			draw_arc(point, nodeRadius, 0.0, TAU, 24, Color.RED, 3.0)

func updateCoM() -> void:
	var sumPositions = Vector2.ZERO
	for i in range(nodeCount):
		sumPositions += listPoints[i].position
	CoM = sumPositions/nodeCount
	
func applyTorque(tau) -> void: # Remember the more important accuracy is no net center of mass force
	var appliedForce = tau / ((listPoints[0].position - CoM).length())
	for i in range(nodeCount):
		listPoints[i].apply_central_force(appliedForce/nodeCount * (listPoints[i].position - CoM).normalized().orthogonal())
		
func updateArrow() -> void:
	arrow.position = CoM
	arrow.rotation = -orientation

@export var MAX_ANGULAR_MOMENTUM = 100000
@export var maxTorque = MAX_ANGULAR_MOMENTUM/0.1
var rollDiffThreshold = 3000

func handle_rotation(delta):
	var roll_input = Input.get_axis("spin_right", "spin_left")
	# if you are slower than the intended angular velocity or moving in the opposite direction
	# also I am making it so that the angular momentum for smaller fish is a bit smaller (in terms of angular 
	# velocity it naturally gets bigger so I am compensating)
	if sign(roll_input) * L < MAX_ANGULAR_MOMENTUM * fishSize and not flipHapenning: 
		var diff = roll_input * MAX_ANGULAR_MOMENTUM * fishSize - L # angular momentum needed to reach goal
		var maxTorqueEffective
		if abs(diff) > rollDiffThreshold:
			if sign(L) != roll_input:
				maxTorqueEffective = 2 * maxTorque
			else:
				maxTorqueEffective  = maxTorque
			var torqueNeeded = sign(diff) * min(abs(diff / (delta)), maxTorqueEffective)
			if frame % 10 == 0:
				print("L ", L, " diff ", diff)
			applyTorque(torqueNeeded)
			
			
"""
Still needs work
"""
func handle_shrink(delta) -> void:
	if Input.is_action_pressed("shrink") and fishSize > minfishSize and not explosionHapenning:
		var newSize = fishSize - shrinkSpeed * delta
		setScale(newSize)
		fishSize = newSize
	pass

func handle_expand(delta) -> void:
	if Input.is_action_pressed("expand") and fishSize < maxfishSize and not explosionHapenning:
		var newSize = fishSize + expandSpeed * delta
		setScale(newSize)
		fishSize = newSize
	pass
	
func handle_flip(delta) -> void:
	var flipDirection = 0.0
	if Input.is_action_just_pressed("flip right") and not flipHapenning:
		flipDirection = -1.0
	elif Input.is_action_just_pressed("flip left") and not flipHapenning:
		flipDirection = 1.0
	if flipDirection != 0:
		# do two spins per flip (can parameterize number of flips maybe)
		var desiredAngularVelocity = 4 * PI / flipTime
		# tau * dt = I * (domega)
		var tauImpulse = I * desiredAngularVelocity / delta
		print(tauImpulse)
		applyTorque(flipDirection * tauImpulse)
		flipHapenning = true
		rotationSinceFlip = 0
		flipTimeRemaining = flipTime
		
	if flipHapenning:
		flipTimeRemaining -= delta
		if flipDirection == 0:
			rotationSinceFlip += wrapf(orientation - previousOrientation, -PI, PI)
		# flip completes one rotation
		var remainingRotation = 2 * PI - abs(rotationSinceFlip)
		if abs(remainingRotation) <= flipStopThreshold or flipTimeRemaining <= 0:
			flipHapenning = false
		elif remainingRotation > 0 and remainingRotation <= PI / 2.0:
			# this is from vfinal^2 = vi^2 - 2ax, setting vfinal = 0, isolating a, and converting to a force (but for the rotational equivalents)
			# since remaining rotation is always positive, the sign is adjusted by opposing the current angular velocity
			var brakingTorque = -sign(angularVelocity) * I * angularVelocity ** 2 / (2.0 * remainingRotation)
			applyTorque(brakingTorque)
			
		
		

# for debugging
var frame = 0

func _physics_process(delta) -> void:
	frame += 1
	"""
	if frame % 10 == 0:
		print("L ", L)
	"""
		
	updateRim()
	updateCoM()
	updateI()
	previousOrientation = orientation
	orientation = (listPoints[0].position - listPoints[nodeCount/2].position).angle_to(Vector2(0,1))
	angularVelocity = (wrapf(orientation - previousOrientation, -PI, PI))/delta
	L = angularVelocity * I
	updateArrow()
	handle_shrink(delta)
	handle_expand(delta)
	handle_rotation(delta)
	
	
	
	
	
	handle_flip(delta)
	# DEALING WITH MOVEMENT
	var dir = (listPoints[0].position - listPoints[nodeCount/2].position).normalized()
	if (not Input.is_action_pressed("up")):
		dir = Vector2(0,0)
	var force_angle = dir.angle_to(Vector2(0,-1))
	var forcedPointsCount = 4
	var forcedCenterIndex = roundi((-force_angle + orientation)*nodeCount/(2*PI))
	var centerNode = listPoints[wrapi(forcedCenterIndex, 0, nodeCount)]
	var oppositeNode = listPoints[wrapi(forcedCenterIndex + nodeCount/2, 0, nodeCount)]
	var forcePerNode = movementForce * dir / (forcedPointsCount + 1)
	var forwardSquishForce = squishForce * dir / (forcedPointsCount + 1)
	var backwardSquishForce = -squishForce * dir / (nodeCount - forcedPointsCount - 1)
	var forwardSquishIndexes := []
	#TODO: for a squishing effect the force should be divided as follows:
	# you have a counter force variable that you apply to all nodes.
	# squishForce/( forced Points + 1) forwards
	# squishForce/ (NodeCount - forcedPoints - 1) backwards
	# when doing the forward forces apply the squish force and add the indeces to an index list
	# in another loop apply all the squishforces for the rest
	#TODO: MAKE PUSHED POINTS A DIFFERENT COLOR FOR DEBUGGING
	var residualTorque = 0
	debugForcePoints.clear()
	for i in range(0, forcedPointsCount/2 +1):
		if i == 0:
			forwardSquishIndexes.append(wrapi(forcedCenterIndex, 0, nodeCount))
			debugForcePoints.append(listPoints[wrapi(forcedCenterIndex, 0, nodeCount)].position)
			listPoints[wrapi(forcedCenterIndex, 0, nodeCount)].apply_central_force(forcePerNode)
			centerNode.apply_central_force(forwardSquishForce)
			residualTorque += (centerNode.position - CoM).cross(forwardSquishForce)
		else:
			var rightNode = listPoints[wrapi(forcedCenterIndex + i, 0, nodeCount)]
			var leftNode = listPoints[wrapi(forcedCenterIndex - i, 0, nodeCount)]
			forwardSquishIndexes.append(wrapi(forcedCenterIndex + i, 0, nodeCount))
			forwardSquishIndexes.append(wrapi(forcedCenterIndex - i, 0, nodeCount))
			debugForcePoints.append(rightNode.position)
			debugForcePoints.append(leftNode.position)
			rightNode.apply_central_force(forcePerNode)
			rightNode.apply_central_force(forwardSquishForce)
			residualTorque += (rightNode.position - CoM).cross(forcePerNode)
			residualTorque += (rightNode.position - CoM).cross(forwardSquishForce)
			leftNode.apply_central_force(forcePerNode)
			leftNode.apply_central_force(forwardSquishForce)
			residualTorque += (leftNode.position - CoM).cross(forcePerNode)
			residualTorque += (leftNode.position - CoM).cross(forwardSquishForce)
	for i in range(nodeCount):
		if not forwardSquishIndexes.has(i):
			listPoints[i].apply_central_force(backwardSquishForce)
			residualTorque += (listPoints[i].position - CoM).cross(backwardSquishForce)
	# cancel the torque by applying a spinning force on both sides
	# compromising slight rotation to make sure this extra force is not doing anything
	# to the linear velocity
	applyTorque(residualTorque)
	if abs(L) < smallL:
		applyTorque( -L/(10*delta))

		
	

	
	
	
	
	

	#TODO: Strong force until some velocity and then only the orthogonal component affects the movement (maybe. More
	# generally, need a speed cap for the fish
	
	#TODO: Add the quick expand mechanic
	#TODO: Add goals
	#TODO: Add more players and then a scoreboard and timer (possibly as part of background?)
	#TODO: Add menu
	
	#TODO: the reason I needed to half the torque to stop properly is that when going to 0 once you are 
	# going in the wrong direction you get double the torque applied in the other direction. Try to fix this.
	# (I might be wrong about this. If I am right, just make the condition for double torque only apply if the gap is large
	# AND you are going in the worng direction. This needs more thought.)
	
	#TODO: adjusting the flip speed acoording to flip time is probably not the best. One good solution is to
	# check (maybe by code) how long a flip takes and then set the flip time manually, and the flip kick 
	# seperately (remember the purpose of this is that if something prevents the player from flipping they should 
	# be able to move after again after a time roughly equal to the time it would have taken to flip
	
	#TODO: ideas: go slower when big, add brake button, 
	#queue_redraw()
	
		
	
	
	
	
	
	

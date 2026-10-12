extends Node2D

const SOFT_BODY_NODE : PackedScene = preload("res://objects/pufferfish/SoftBodyNode.tscn")

@export_category("Player Info")
@export var player_id: int = 0
@export var body_color: Color = Color.BLUE_VIOLET
@export var rim_color: Color = Color.BLUE
# Debugging variables

# drawing stuff (right now just the nodes that are being pushed)
var draw_on = false

@export_category("Connections")
@export var visual_polygon : Polygon2D
@export var visual_rim : Line2D
@export var arrow : Sprite2D
@export var rim_balls_root : Node2D

@export_category("Ball config")
# Keep this even (TODO: make a warning/throw an error if not)
@export var rim_ball_count : int = 30  ##Amount of softBodyNodes the pufferfish has
@export var radius : float = 50        ##Ball total radius, including node collision sizes
@export var rim_ball_radius: float = 10  ##Node collider radii
@export var ball_mass : float = 10
@export var stiffness_curve : Curve = Curve.new()
@export var damping_curve : Curve = Curve.new()
@export var movement_force: float = 5000
@export var spin_torque: float = 100000
@export var squish_force: float = 30000
@export var spin_damping: float = 10000

@export_category("Shrink expand")
@export var shrink_speed: float = 2.2
@export var expand_speed: float = 2.2
@export var shrink_time : float = 0.05
@export var expand_time : float = 0.15
@export_range(0.1,1.0,0.01) var shrink_factor : float = 0.4 

@export_category("Other")
# If the angular momentum is smaller than this, apply damping
@export var small_l = 300 * ball_mass

var orientation : float = 0.0
var previous_orientation : float = orientation
var angular_velocity : float = 0.0


var rim_balls_list : Array[RigidBody2D] = []
var joints_list := []
var list_resting_dists := []
var debug_force_points := []

# Is this right? Is global position the com of the spawn position
var CoM : Vector2 = global_position
var previous_CoM : Vector2 = CoM
# var CoM_velocity = 0.0

var fish_size := 1.0
var max_fish_size := 1.3
var min_fish_size := 0.4

var I: float
var L = angular_velocity * I

var flip_hapenning : bool = false
var rotation_since_flip : float = 0
var flip_time_remaining : float = 0
@export var flip_time : float = 0.5
@export var flip_stop_threshold : float = 0.05

var explosion_hapenning : bool
var time_since_explosions : float

@export var MAX_ANGULAR_MOMENTUM = 100000
@export var max_torque = MAX_ANGULAR_MOMENTUM/0.1
var roll_diff_threshold = 3000

# Inputs
var _acceleration_input: float = 0.0
var _turning_input: float = 0.0
var _scale_input: float = 0.0
var _flipped_left: bool = false
var _flipped_right: bool = false


func _ready() -> void:
	# init visuals from values
	visual_rim.width = 2 * rim_ball_radius
	visual_polygon.color = body_color
	visual_rim.default_color = rim_color

	_create_rim_balls()

# for debugging
var frame = 0

func _physics_process(delta) -> void:
	frame += 1
	#
	# if frame % 10 == 0:
	# 	print("L ", L)
	#
	
	_get_inputs()
	
	update_CoM()
	update_I()
	previous_orientation = orientation
	orientation = (rim_balls_list[0].position - rim_balls_list[floori(rim_ball_count/2.0)].position).angle_to(Vector2(0,1))
	angular_velocity = (wrapf(orientation - previous_orientation, -PI, PI))/delta
	L = angular_velocity * I

	#inputs
	_handle_scale(delta)
	_handle_turning(delta)
	_handle_flip(delta)

	_move(delta)

	_update_visuals()

func _move(delta):
	# DEALING WITH MOVEMENT
	var dir = (rim_balls_list[0].position - rim_balls_list[floori(rim_ball_count/2.0)].position).normalized()
	var force_angle = dir.angle_to(Vector2(0,-1))
	var forced_points_count = 4
	var forced_center_index = roundi((-force_angle + orientation)*rim_ball_count/(2*PI))
	var center_rim_ball = rim_balls_list[wrapi(forced_center_index, 0, rim_ball_count)]
	# var oppositeNode = rim_balls_list[wrapi(forcedCenterIndex + rim_ball_count/2, 0, rim_ball_count)]
	var force_per_rimball = movement_force * _acceleration_input * dir / (forced_points_count + 1)
	var forward_squish_force = squish_force * _acceleration_input * dir / (forced_points_count + 1)
	var backward_squish_force = -squish_force * _acceleration_input * dir / (rim_ball_count - forced_points_count - 1)
	var forward_squish_indexes := []
	#TODO: for a squishing effect the force should be divided as follows:
	# you have a counter force variable that you apply to all nodes.
	# squish_force/( forced Points + 1) forwards
	# squish_force/ (NodeCount - forcedPoints - 1) backwards
	# when doing the forward forces apply the squish force and add the indeces to an index list
	# in another loop apply all the squishforces for the rest
	#TODO: MAKE PUSHED POINTS A DIFFERENT COLOR FOR DEBUGGING
	var residual_torque = 0
	debug_force_points.clear()
	for i in range(0, floori(forced_points_count/2.0) +1):
		if i == 0:
			forward_squish_indexes.append(wrapi(forced_center_index, 0, rim_ball_count))
			debug_force_points.append(rim_balls_list[wrapi(forced_center_index, 0, rim_ball_count)].position)
			rim_balls_list[wrapi(forced_center_index, 0, rim_ball_count)].apply_central_force(force_per_rimball)
			center_rim_ball.apply_central_force(forward_squish_force)
			residual_torque += (center_rim_ball.position - CoM).cross(forward_squish_force)
		else:
			var right_rimball = rim_balls_list[wrapi(forced_center_index + i, 0, rim_ball_count)]
			var left_rimball = rim_balls_list[wrapi(forced_center_index - i, 0, rim_ball_count)]
			forward_squish_indexes.append(wrapi(forced_center_index + i, 0, rim_ball_count))
			forward_squish_indexes.append(wrapi(forced_center_index - i, 0, rim_ball_count))
			debug_force_points.append(right_rimball.position)
			debug_force_points.append(left_rimball.position)
			right_rimball.apply_central_force(force_per_rimball)
			right_rimball.apply_central_force(forward_squish_force)
			residual_torque += (right_rimball.position - CoM).cross(force_per_rimball)
			residual_torque += (right_rimball.position - CoM).cross(forward_squish_force)
			left_rimball.apply_central_force(force_per_rimball)
			left_rimball.apply_central_force(forward_squish_force)
			residual_torque += (left_rimball.position - CoM).cross(force_per_rimball)
			residual_torque += (left_rimball.position - CoM).cross(forward_squish_force)
	for i in range(rim_ball_count):
		if not forward_squish_indexes.has(i):
			rim_balls_list[i].apply_central_force(backward_squish_force)
			residual_torque += (rim_balls_list[i].position - CoM).cross(backward_squish_force)
	# cancel the torque by applying a spinning force on both sides
	# compromising slight rotation to make sure this extra force is not doing anything
	# to the linear velocity
	apply_torque(residual_torque)
	if abs(L) < small_l:
		apply_torque( -L/(10*delta))

func _get_inputs() -> void:
	_acceleration_input = Input.get_action_strength("p%d_accelerate" %(player_id+1))
	_turning_input = Input.get_axis("p%d_turn_right" %(player_id+1), "p%d_turn_left" %(player_id+1))
	_scale_input = Input.get_axis("p%d_shrink" %(player_id+1), "p%d_expand" %(player_id+1))
	_flipped_left = Input.is_action_just_pressed("p%d_flip_left" %(player_id+1))
	_flipped_right = Input.is_action_just_pressed("p%d_flip_right" %(player_id+1))

func _create_rim_balls() -> void:
	# create rim balls
	for i in range(rim_ball_count):
		var rim_ball : RigidBody2D = SOFT_BODY_NODE.instantiate()
		rim_ball.mass = ball_mass / rim_ball_count
		rim_balls_root.add_child(rim_ball)
		rim_balls_list.append(rim_ball)
		rim_ball.global_position = global_position + Vector2(0,radius - rim_ball_radius).rotated(2 * PI * i / rim_ball_count)
		for a in rim_ball.get_children():
			a.scale = Vector2(rim_ball_radius/50.0, rim_ball_radius/50.0)	## In SoftBodyNode.tscn, the radius is 50
	
	# go over every unique pair of rim balls
	for i in range(rim_balls_list.size()):
		for j in range(i+1, rim_balls_list.size()):
			# add make rim balls not collide
			rim_balls_list[i].add_collision_exception_with(rim_balls_list[j])
			rim_balls_list[j].add_collision_exception_with(rim_balls_list[i])
			# create joint
			var stiffness_amount = 0.5 * (rim_balls_list[i].position - rim_balls_list[j].position).length() / (radius - rim_ball_radius)
			var joint = _create_joint(rim_balls_list[i],rim_balls_list[j], stiffness_curve.sample(stiffness_amount), damping_curve.sample(stiffness_amount))
			rim_balls_root.add_child(joint)
			joints_list.append(joint)
			list_resting_dists.append(joint.rest_length)

func _create_joint(a : Node2D, b:Node2D, stiffness : float = 700, damping : float = 0.6) -> DampedSpringJoint2D:
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

func update_I() -> void:
	#
	#  Calculates the moment of inertia of the fish
	#
	var inertia = 0
	for ball in rim_balls_list:
		inertia += ball.mass * (ball.position - CoM).length()**2
	I = inertia


func set_ball_scale(s : float):
	for i in range(joints_list.size()):
		joints_list[i].rest_length = list_resting_dists[i] * s

func _update_visuals() -> void:
	var points = []
	for ball in rim_balls_list:
		points.append(ball.position)
	visual_polygon.polygon = points
	visual_rim.points = points
	# update arrow
	arrow.position = CoM + Vector2.from_angle(-orientation+PI/2.0) * fish_size * (radius + rim_ball_radius/2.0)
	arrow.rotation = -orientation

# for debugging which nodes are being pushed
func _draw() -> void:
	if draw_on:
		for point in debug_force_points:
			draw_arc(point, rim_ball_radius, 0.0, TAU, 24, Color.RED, 3.0)

func update_CoM() -> void:
	var sum_positions = Vector2.ZERO
	for i in range(rim_ball_count):
		sum_positions += rim_balls_list[i].position
	CoM = sum_positions/rim_ball_count

func apply_torque(tau) -> void: # Remember the more important accuracy is no net center of mass force
	var applied_force = tau / ((rim_balls_list[0].position - CoM).length())
	for i in range(rim_ball_count):
		rim_balls_list[i].apply_central_force(applied_force/rim_ball_count * (rim_balls_list[i].position - CoM).normalized().orthogonal())

func _handle_turning(delta):
	# if you are slower than the intended angular velocity or moving in the opposite direction
	# also I am making it so that the angular momentum for smaller fish is a bit smaller (in terms of angular 
	# velocity it naturally gets bigger so I am compensating)
	if sign(_turning_input) * L < MAX_ANGULAR_MOMENTUM * fish_size and not flip_hapenning: 
		var diff = _turning_input * MAX_ANGULAR_MOMENTUM * fish_size - L # angular momentum needed to reach goal
		var max_torque_effective
		if abs(diff) > roll_diff_threshold:
			if sign(L) != _turning_input:
				max_torque_effective = 2 * max_torque
			else:
				max_torque_effective  = max_torque
			var torque_needed = sign(diff) * min(abs(diff / (delta)), max_torque_effective)
			if frame % 10 == 0:
				print("L ", L, " diff ", diff)
			apply_torque(torque_needed)

#Still needs work

func _handle_scale(delta) -> void:
	if _scale_input == 0.0 or explosion_hapenning: return
	var new_fish_size = clampf(fish_size + shrink_speed * _scale_input * delta, min_fish_size, max_fish_size)
	if new_fish_size != fish_size: set_ball_scale(new_fish_size)
	fish_size = new_fish_size

func _handle_flip(delta) -> void:
	var flipDirection = 0.0
	if _flipped_left and not flip_hapenning:
		flipDirection = -1.0
	elif _flipped_right and not flip_hapenning:
		flipDirection = 1.0
	if flipDirection != 0:
		# do two spins per flip (can parameterize number of flips maybe)
		var desiredAngularVelocity = 4 * PI / flip_time
		# tau * dt = I * (domega)
		var tauImpulse = I * desiredAngularVelocity / delta
		print(tauImpulse)
		apply_torque(flipDirection * tauImpulse)
		flip_hapenning = true
		rotation_since_flip = 0
		flip_time_remaining = flip_time
		
	if flip_hapenning:
		flip_time_remaining -= delta
		if flipDirection == 0:
			rotation_since_flip += wrapf(orientation - previous_orientation, -PI, PI)
		# flip completes one rotation
		var remainingRotation = 2 * PI - abs(rotation_since_flip)
		if abs(remainingRotation) <= flip_stop_threshold or flip_time_remaining <= 0:
			flip_hapenning = false
		elif remainingRotation > 0 and remainingRotation <= PI / 2.0:
			# this is from vfinal^2 = vi^2 - 2ax, setting vfinal = 0, isolating a, and converting to a force (but for the rotational equivalents)
			# since remaining rotation is always positive, the sign is adjusted by opposing the current angular velocity
			var brakingTorque = -sign(angular_velocity) * I * angular_velocity ** 2 / (2.0 * remainingRotation)
			apply_torque(brakingTorque)

# var scaleTween : Tween
# var pushAmount: float = 0.0
# func _input(event: InputEvent) -> void:
# 	if (event is InputEventMouseButton):
# 		if(scaleTween != null):
# 			scaleTween.stop()
# 		scaleTween = get_tree().create_tween()
# 		if (event.pressed):
# 			scaleTween.tween_method(set_ball_scale, 1.0, shrink_factor, shrink_time).set_trans(Tween.TRANS_LINEAR)
# 		else:
# 			scaleTween.tween_method(set_ball_scale, shrink_factor, 1.0, expand_time).set_trans(Tween.TRANS_LINEAR)
# 		scaleTween.play()
# 	

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

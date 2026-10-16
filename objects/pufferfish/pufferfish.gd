class_name Pufferfish extends Node2D

const RIM_BALL_SCENE : PackedScene = preload("res://objects/pufferfish/SoftBodyNode.tscn")

# debug drawing stuff (right now just the nodes that are being pushed)
var draw_on = false
var debug_force_points := []
var frame = 0

@export_category("Connections")
@export var visual_polygon : Polygon2D
@export var visual_rim : Line2D
@export var arrow : Sprite2D
@export var rim_balls_root : Node2D

@export_category("Player Info")
@export var player_id: int = 0
@export var body_color: Color = Color.BLUE_VIOLET
@export var rim_color: Color = Color.BLUE

@export_category("Ball config")
# Keep this even (TODO: make a warning/throw an error if not)
@export var _movement_force: float = 5000
@export var _rim_ball_count : int = 30  ## Amount of rim balls the pufferfish has
@export var _radius : float = 50        ## pufferfish ball total _radius, including rim balls
@export var _rim_ball_radius: float = 10
@export var _fish_mass: float = 10
@export var _stiffness_curve : Curve = Curve.new()
@export var _damping_curve : Curve = Curve.new()
@export var _squish_force: float = 30000
# @export var spin_damping: float = 10000
# @export var spin_torque: float = 100000

@export_category("Shrink expand")
@export var _scale_speed = 2.2
# different for each explosion depending on the initial size
@export var _explosion_rate: float = 100
var _is_recovering_from_explosion: bool = false
@export var _explosion_max_scale_addition = 0.2

# @export_range(0.1,1.0,0.01) var shrink_factor : float = 0.4
# @export var shrink_time : float = 0.05
# @export var expand_time : float = 0.15

@export_category("Other")
# If the angular momentum is smaller than this, apply damping
@export var small_l = 300 * _fish_mass
# apply this so that changing mass is not completely momentum conserving
@export var _drag_correction : float  = 1.0

@export var _flip_time : float = 0.5
@export var _flip_stop_threshold : float = 0.05

@export var _max_angular_momentum = 100000
@export var _max_torque = _max_angular_momentum/0.1
var _roll_diff_threshold = 3000

var _reference_ball : int = 0
var _dir : Vector2 = Vector2(0.0, 0.0)
var _orientation : float = 0.0
var _previous_orientation : float = _orientation
var _rotation_just_set = false
var _angular_velocity : float = 0.0

var _rim_balls_list : Array[RigidBody2D] = []
var _joints_list : Array[DampedSpringJoint2D]= []
var _list_resting_dists : Array[float] = []

# Is this right? Is global position the com of the spawn position
var _CoM : Vector2 = global_position
var _previous_CoM : Vector2 = _CoM
var _CoM_velocity = 0.0


var _fish_scale := 1.0
var _previous_fish_scale = _fish_scale
var _max_fish_scale := 1.3
var _min_fish_scale := 0.7

var _I: float
var _L = _angular_velocity * _I

var _flip_hapenning : bool = false
var _rotation_since_flip : float = 0
var _flip_time_remaining : float = 0

var _explosion_hapenning : bool = false


# Inputs
var _acceleration_input: float = 0.0
var _turning_input: float = 0.0
var _scale_input: float = 0.0
var _flipped_left: bool = false
var _flipped_right: bool = false
var _exploded: bool = false


func _ready() -> void:
	# init visuals from values
	visual_rim.width = 2 * _rim_ball_radius
	visual_polygon.color = body_color
	visual_rim.default_color = rim_color

	_create_rim_balls()
	_update_visuals()

func _physics_process(delta) -> void:
	frame += 1
	#
	# if frame % 10 == 0:
	# 	print("_L ", _L)
	#
	
	_get_inputs()
	_previous_fish_scale = _fish_scale
	_handle_scale(delta)
	update_mass()
	update_CoM()
	update_I()
	_previous_orientation = _orientation
	update_direction_and_orientation()
	update_angular_velocity(delta)
	_L = _angular_velocity * _I

	
	_handle_turning(delta)
	_handle_flip(delta)
	_handle_explosion(delta)
	update_velocity(delta)
	_move(delta)
	_apply_mass_changing_drag(delta)
	_previous_CoM = _CoM

	_update_visuals()

func _move(delta):
	# DEALING WITH MOVEMENT
	var forced_points_count = 4
	var forced_center_index = (_reference_ball + _rim_ball_count/2) % _rim_ball_count
	var center_rim_ball = _rim_balls_list[wrapi(forced_center_index, 0, _rim_ball_count)]
	# var oppositeNode = _rim_balls_list[wrapi(forcedCenterIndex + _rim_ball_count/2, 0, _rim_ball_count)]
	var force_per_rimball = _movement_force * _acceleration_input * _dir / (forced_points_count + 1)
	var forward_squish_force = _squish_force * _acceleration_input * _dir / (forced_points_count + 1)
	var backward_squish_force = -_squish_force * _acceleration_input * _dir / (_rim_ball_count - forced_points_count - 1)
	var forward_squish_indexes := []
	#TODO: for a squishing effect the force should be divided as follows:
	# you have a counter force variable that you apply to all nodes.
	# _squish_force/( forced Points + 1) forwards
	# _squish_force/ (NodeCount - forcedPoints - 1) backwards
	# when doing the forward forces apply the squish force and add the indeces to an index list
	# in another loop apply all the squishforces for the rest
	#TODO: MAKE PUSHED POINTS A DIFFERENT COLOR FOR DEBUGGING
	var residual_torque = 0
	debug_force_points.clear()
	for i in range(0, floori(forced_points_count/2.0) +1):
		if i == 0:
			forward_squish_indexes.append(wrapi(forced_center_index, 0, _rim_ball_count))
			debug_force_points.append(_rim_balls_list[wrapi(forced_center_index, 0, _rim_ball_count)].position)
			_rim_balls_list[wrapi(forced_center_index, 0, _rim_ball_count)].apply_central_force(force_per_rimball)
			center_rim_ball.apply_central_force(forward_squish_force)
			residual_torque += (center_rim_ball.position - _CoM).cross(forward_squish_force)
		else:
			var right_rimball = _rim_balls_list[wrapi(forced_center_index + i, 0, _rim_ball_count)]
			var left_rimball = _rim_balls_list[wrapi(forced_center_index - i, 0, _rim_ball_count)]
			forward_squish_indexes.append(wrapi(forced_center_index + i, 0, _rim_ball_count))
			forward_squish_indexes.append(wrapi(forced_center_index - i, 0, _rim_ball_count))
			debug_force_points.append(right_rimball.position)
			debug_force_points.append(left_rimball.position)
			right_rimball.apply_central_force(force_per_rimball)
			right_rimball.apply_central_force(forward_squish_force)
			residual_torque += (right_rimball.position - _CoM).cross(force_per_rimball)
			residual_torque += (right_rimball.position - _CoM).cross(forward_squish_force)
			left_rimball.apply_central_force(force_per_rimball)
			left_rimball.apply_central_force(forward_squish_force)
			residual_torque += (left_rimball.position - _CoM).cross(force_per_rimball)
			residual_torque += (left_rimball.position - _CoM).cross(forward_squish_force)
	for i in range(_rim_ball_count):
		if not forward_squish_indexes.has(i):
			_rim_balls_list[i].apply_central_force(backward_squish_force)
			residual_torque += (_rim_balls_list[i].position - _CoM).cross(backward_squish_force)
	# cancel the torque by applying a spinning force on both sides
	# compromising slight rotation to make sure this extra force is not doing anything
	# to the linear velocity
	_apply_torque(residual_torque)
	if abs(_L) < small_l:
		_apply_torque( -_L/(10*delta))

func _get_inputs() -> void:
	_acceleration_input = Input.get_action_strength("p%d_accelerate" %(player_id+1))
	_turning_input = Input.get_axis("p%d_turn_right" %(player_id+1), "p%d_turn_left" %(player_id+1))
	_scale_input = Input.get_axis("p%d_shrink" %(player_id+1), "p%d_expand" %(player_id+1))
	_flipped_left = Input.is_action_just_pressed("p%d_flip_left" %(player_id+1))
	_flipped_right = Input.is_action_just_pressed("p%d_flip_right" %(player_id+1))
	_exploded = Input.is_action_just_pressed("p%d_explode" %(player_id+1))

func _create_rim_balls() -> void:
	# create rim balls
	for i in range(_rim_ball_count):
		var rim_ball : RigidBody2D = RIM_BALL_SCENE.instantiate()
		rim_ball.mass = _fish_mass / _rim_ball_count
		rim_balls_root.add_child(rim_ball)
		_rim_balls_list.append(rim_ball)
		rim_ball.global_position = global_position + Vector2(0,_radius - _rim_ball_radius).rotated(2 * PI * i / _rim_ball_count)
		for a in rim_ball.get_children():
			a.scale = Vector2(_rim_ball_radius/50.0, _rim_ball_radius/50.0)	## In SoftBodyNode.tscn, the _radius is 50
	
	# go over every unique pair of rim balls
	for i in range(_rim_balls_list.size()):
		for j in range(i+1, _rim_balls_list.size()):
			# add make rim balls not collide
			_rim_balls_list[i].add_collision_exception_with(_rim_balls_list[j])
			_rim_balls_list[j].add_collision_exception_with(_rim_balls_list[i])
			# create joint
			var stiffness_amount = 0.5 * (_rim_balls_list[i].position - _rim_balls_list[j].position).length() / (_radius - _rim_ball_radius)
			var joint = _create_joint(_rim_balls_list[i],_rim_balls_list[j], _stiffness_curve.sample(stiffness_amount), _damping_curve.sample(stiffness_amount))
			rim_balls_root.add_child(joint)
			_joints_list.append(joint)
			_list_resting_dists.append(joint.rest_length)

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

func update_mass() -> void:
	for ball in _rim_balls_list:
		ball.mass = (_fish_mass / _rim_ball_count) * _fish_scale
		
	
	
func update_I() -> void:
	#
	#  Calculates the moment of inertia of the fish
	#
	var inertia = 0
	for ball in _rim_balls_list:
		inertia += ball.mass * (ball.position - _CoM).length()**2
	_I = inertia
	
func update_direction_and_orientation() -> void:
	_dir = (_rim_balls_list[_reference_ball].position - 
	_rim_balls_list[(_reference_ball + _rim_ball_count/2) % _rim_ball_count].position).normalized()
	_orientation = _dir.angle_to(Vector2(0,1))
	
func update_angular_velocity(delta):
	if _rotation_just_set:
		_rotation_just_set = false
	else:
		_angular_velocity = (wrapf(_orientation - _previous_orientation, -PI, PI))/delta

func set_ball_scale(s : float):
	_fish_scale = s
	for i in range(_joints_list.size()):
		_joints_list[i].rest_length = _list_resting_dists[i] * s
		

func _update_visuals() -> void:
	var points = []
	for ball in _rim_balls_list:
		points.append(ball.position)
	visual_polygon.polygon = points
	visual_rim.points = points
	# update arrow
	arrow.position = _CoM + Vector2.from_angle(-_orientation+PI/2.0) * _fish_scale * (_radius + _rim_ball_radius/2.0)
	arrow.rotation = -_orientation

# for debugging which nodes are being pushed
func _draw() -> void:
	if draw_on:
		for point in debug_force_points:
			draw_arc(point, _rim_ball_radius, 0.0, TAU, 24, Color.RED, 3.0)

func update_CoM() -> void:
	var sum_positions = Vector2.ZERO
	for i in range(_rim_ball_count):
		sum_positions += _rim_balls_list[i].position
	_CoM = sum_positions/_rim_ball_count

func _apply_torque(tau) -> void: # Remember the more important accuracy is no net center of mass force
	var applied_force = tau / ((_rim_balls_list[0].position - _CoM).length())
	for i in range(_rim_ball_count):
		_rim_balls_list[i].apply_central_force(applied_force/_rim_ball_count * (_rim_balls_list[i].position - _CoM).normalized().orthogonal())

func _handle_turning(delta):
	# if you are slower than the intended angular velocity or moving in the opposite direction
	# also _I am making it so that the angular momentum for smaller fish is a bit smaller (in terms of angular 
	# velocity it naturally gets bigger so _I am compensating)
	if sign(_turning_input) * _L < _max_angular_momentum * _fish_scale and not _flip_hapenning: 
		var diff = _turning_input * _max_angular_momentum * _fish_scale - _L # angular momentum needed to reach goal
		var max_torque_effective
		if abs(diff) > _roll_diff_threshold:
			if sign(_L) != _turning_input:
				max_torque_effective = 2 * _max_torque * _fish_scale
			else:
				max_torque_effective  = _max_torque * _fish_scale
			var torque_needed = sign(diff) * min(abs(diff / (delta)), max_torque_effective)
			if frame % 10 == 0:
				print("_L ", _L, " diff ", diff)
			_apply_torque(torque_needed)

func update_velocity(delta):
	_CoM_velocity = (_CoM - _previous_CoM)/delta

func _handle_scale(delta) -> void:
	if _explosion_hapenning: return
	var new_fish_size = clampf(_fish_scale + _scale_speed * _scale_input * delta, _min_fish_scale, _max_fish_scale)
	if new_fish_size != _fish_scale: set_ball_scale(new_fish_size)
	
func _apply_mass_changing_drag(delta) -> void:
	var momentum_added = _fish_mass * (_fish_scale - _previous_fish_scale) * _CoM_velocity
	for ball in _rim_balls_list:
		ball.apply_central_force(-momentum_added  / (delta * _drag_correction * _rim_ball_count))
		


		
func _handle_explosion(delta) -> void:
	if _exploded and not _explosion_hapenning:
		print("kaboom")
		_explosion_hapenning = true
	if _explosion_hapenning and not _is_recovering_from_explosion:
		set_ball_scale(clamp(_fish_scale + _explosion_rate * delta, 0, _max_fish_scale + _explosion_max_scale_addition))
	if _explosion_hapenning and _fish_scale >= _max_fish_scale + _explosion_max_scale_addition:
		_is_recovering_from_explosion = true
	if _is_recovering_from_explosion:
		set_ball_scale(_fish_scale - _scale_speed * delta)
		print("here")
	if _is_recovering_from_explosion and _fish_scale <= _max_fish_scale:
		_is_recovering_from_explosion = false
		_explosion_hapenning = false
		
		
		
		
	
	
func _handle_flip(delta) -> void:
	var flipDirection = 0.0
	if _flipped_left and not _flip_hapenning:
		flipDirection = 1.0
	elif _flipped_right and not _flip_hapenning:
		flipDirection = -1.0
	if flipDirection != 0:
		# do two spins per flip (can parameterize number of flips maybe)
		var desiredAngularVelocity = 4 * PI / _flip_time
		# tau * dt = _I * (domega)
		var tauImpulse = _I * desiredAngularVelocity / delta
		_apply_torque(flipDirection * tauImpulse)
		_flip_hapenning = true
		_rotation_since_flip = 0
		_flip_time_remaining = _flip_time
		
	if _flip_hapenning:
		_flip_time_remaining -= delta
		if flipDirection == 0:
			_rotation_since_flip += wrapf(_orientation - _previous_orientation, -PI, PI)
		# flip completes one rotation
		var remainingRotation = 2 * PI - abs(_rotation_since_flip)
		if abs(remainingRotation) <= _flip_stop_threshold or _flip_time_remaining <= 0:
			_flip_hapenning = false
		elif remainingRotation > 0 and remainingRotation <= PI / 2.0:
			# this is from vfinal^2 = vi^2 - 2ax, setting vfinal = 0, isolating a, and converting to a force (but for the rotational equivalents)
			# since remaining rotation is always positive, the sign is adjusted by opposing the current angular velocity
			var brakingTorque = -sign(_angular_velocity) * _I * _angular_velocity ** 2 / (2.0 * remainingRotation)
			_apply_torque(brakingTorque)

## Cancel all forces and reset values
func _reset_attributes() -> void:
	_I = 0
	_L = 0
	_CoM_velocity = 0
	_angular_velocity = 0
	set_ball_scale(1)
	pass

## Set pufferfish _orientation in degrees. Set arbitrary = true if when called, the fish is in an arbitrary rotation
func set_orientation(r: float, arbitrary : bool = false) -> void:
	var r_radian = deg_to_rad(r)
	var closest_ball = 0
	var min_angle_distnace = PI
	if arbitrary:
		for i in range(_rim_ball_count):
			var angle = (_rim_balls_list[i].position - 
			_rim_balls_list[floori(i + _rim_ball_count/2.0) % _rim_ball_count].position).angle_to(Vector2(0,1))
			var angle_distance = abs(angle - r_radian)
			if angle_distance < min_angle_distnace:
				closest_ball = i
				min_angle_distnace = angle_distance
	else:
		closest_ball = roundi(-r_radian/(2*PI) * _rim_ball_count)
			
	# this variable is used so that we don't accidentally calculate a huge angular momentum (which would result in a torque)
	_rotation_just_set = true
	_reference_ball = closest_ball


## Teleport pufferfish to given position and reset to default
func force_position(pos: Vector2) -> void:
	_reset_attributes()
	for i in range(len(_rim_balls_list)):
		var rim_ball_position = pos + Vector2(0,_radius - _rim_ball_radius).rotated(2 * PI * i / _rim_ball_count)
		_rim_balls_list[i].force_position(rim_ball_position) 
	
	


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


#TODO: Strong force until some velocity and then only the orthogonal component affects the movement (maybe. More
# generally, need a speed cap for the fish

#TODO: Add the quick expand mechanic
#TODO: Add more players and then a scoreboard and timer (possibly as part of background?)
#TODO: Add menu

#TODO: the reason _I needed to half the torque to stop properly is that when going to 0 once you are 
# going in the wrong direction you get double the torque applied in the other direction. Try to fix this.
# (_I might be wrong about this. If _I am right, just make the condition for double torque only apply if the gap is large
# AND you are going in the worng direction. This needs more thought.)

#TODO: adjusting the flip speed acoording to flip time is probably not the best. One good solution is to
# check (maybe by code) how long a flip takes and then set the flip time manually, and the flip kick 
# seperately (remember the purpose of this is that if something prevents the player from flipping they should 
# be able to move after again after a time roughly equal to the time it would have taken to flip

#TODO: ideas: go slower when big, add brake button, play around with friction for flip feel,
# have a maximum speed for rotation (maybe set rotation speed directly)

#TODO: phyisics optimizations: friction to adjust flip feel (pretty good rn)

#TODO: make movement smoother by amplifying the turning component? Dependent on velocity? Check examples online

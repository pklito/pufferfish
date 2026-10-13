class_name Ball extends RigidBody2D


var _queue_move: bool = false
var _move_pos: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _queue_move:
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		var t = state.transform
		t.origin = _move_pos
		state.transform = t

		_queue_move = false

func force_position(pos: Vector2) -> void:
	_move_pos = pos
	_queue_move = true

extends RigidBody2D


var _queue_move: bool = false
var _move_pos: Vector2 = Vector2.ZERO


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _queue_move:
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		var t: Transform2D = state.transform
		t.origin = _move_pos
		state.transform = t
		_queue_move = false

func force_position(pos: Vector2) -> void:
	_move_pos = pos
	_queue_move = true

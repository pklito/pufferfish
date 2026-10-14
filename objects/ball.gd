class_name Ball extends RigidBody2D

const BALL_SPRITE_SIZE := 512.0

@export var radius: float = 20.0

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite2D

var _queue_move: bool = false
var _move_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	_update_radius()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _queue_move:
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		var t: Transform2D = state.transform
		t.origin = _move_pos
		state.transform = t

		_queue_move = false

func _update_radius() -> void:
	_collision.shape.radius = radius
	var s = radius*2.0 / BALL_SPRITE_SIZE
	_sprite.scale = Vector2(s, s)


func force_position(pos: Vector2) -> void:
	_move_pos = pos
	_queue_move = true

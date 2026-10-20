class_name UI extends Control

@export var _left_score_label: Label
@export var _right_score_label: Label
@export var _game_timer_label: Label

@export var _round_timer:Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

## Gets seconds, returns string of clock display M:SS
func _format_seconds(seconds: float) -> String:
	var m := int(ceili(seconds) / 60.0)
	var s := ceili(seconds) % 60

	return "%d:%02d" % [m, s]

func update_game_timer(seconds_left: float) -> void:
	if seconds_left < 0.0: seconds_left = 0.0
	_game_timer_label.text = _format_seconds(seconds_left)

func update_round_timer(seconds_left: float) -> void:
	if seconds_left <= 0: _round_timer.visible = false
	else: _round_timer.visible = true
	_round_timer.text = str(ceili(seconds_left))

func update_score(left_score: int, right_score: int) -> void:
	_left_score_label.text = str(left_score)
	_right_score_label.text = str(right_score)

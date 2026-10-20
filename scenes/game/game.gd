class_name Game extends Node

enum Team { LEFT, RIGHT }

## Settings for current game
class GameSettings:
	## time of game in seconds
	var game_time: float = 120.0
	## Array of player settings for current game
	var players_settings: Array[Pufferfish.PlayerSettings] = []

@export_category("Editor overrides")
@export var _enable_overrides: bool = false
@export_range(2,6) var player_count: int = 2
@export_range(0,6) var left_team_count: int = 1

#TODO: maybe make this a global variable
var settings: GameSettings = GameSettings.new()

@onready var field: Field = $Field

func _ready() -> void:
	if _enable_overrides: _apply_editor_overrides()

	# connect field signals
	field.goal_scored.connect(_on_field_goal_scored)

	start_game()

func start_game() -> void:
	# setup field for game
	field.setup(settings.players_settings)
	# TODO: wait for field to be ready
	# start round
	field.new_round()

func _on_field_goal_scored(_team: Variant) -> void:
	print("score yippe hooray")
	field.new_round()

func _apply_editor_overrides() -> void:
	var temp = left_team_count
	for i in range(player_count):
		var p = Pufferfish.PlayerSettings.new()
		p.id = i
		if temp > 0: p.team = Game.Team.LEFT
		else: p.team = Game.Team.RIGHT
		temp -= 1
		settings.players_settings.append(p)

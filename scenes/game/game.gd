class_name Game extends Node

signal game_ended

enum Team { LEFT, RIGHT }

## Settings for current game
class GameSettings:
	## time of game in seconds
	var game_time: float = 120.0
	## Array of [PlayerSettings] for current game
	var players_settings: Array[Pufferfish.PlayerSettings] = []

enum Phase { PRE_GAME, ROUND_START, DURING_ROUND, ROUND_END, NONE }

@export_category("Game Settings")
@export_range(0.0,10.0) var _pre_game_time: float = 5.0
@export_range(0.0,10.0) var _pre_round_time: float = 3.0
@export_range(0.0,10.0) var _post_goal_time: float = 2.0

@export_category("Editor overrides")
@export var _enable_overrides: bool = false
@export_range(2,6) var player_count: int = 2
@export_range(0,6) var left_team_count: int = 1

@onready var _field: Field = $Field
@onready var _ui: UI = $CanvasLayer/UI

## settings for current game
var _settings: GameSettings
## current phase of the game
var _current_phase: Phase = Phase.NONE
## timer used to check when phases end
var _phase_timer: float

# team scores
var _left_score: int = 0
var _right_score: int = 0
# time passed in Phase.DURING_ROUND phase
var _elapsed_time: float = 0.0

func _ready() -> void:
	if _enable_overrides: _apply_editor_overrides()
	# connect signals
	_field.goal_scored.connect(_on_field_goal_scored)

func _physics_process(delta: float) -> void:
	# update time for each phase
	match _current_phase:
		Phase.PRE_GAME:
			if _phase_timer <= 0.0:
				_set_phase(Phase.ROUND_START)
		Phase.ROUND_START:
			# update pre round timer
			_ui.update_round_timer(_phase_timer)
			if _phase_timer <= 0.0:
				_set_phase(Phase.DURING_ROUND)
		Phase.DURING_ROUND:
			# update timer
			_ui.update_game_timer(_settings.game_time - _elapsed_time)
			# check if game is over
			if _elapsed_time >= _settings.game_time:
				_on_game_end()
			_elapsed_time += delta
		Phase.ROUND_END:
			if _phase_timer <= 0.0:
				_set_phase(Phase.ROUND_START)
	_phase_timer -= delta


## called when the game timer reaches 0
func _on_game_end():
	# TODO: add game end phase and timer and epic stuff
	game_ended.emit()

## set current game phase
func _set_phase(phase: Phase) -> void:
	match phase:
		Phase.PRE_GAME:
			_phase_timer = _pre_game_time
			_field.freeze_players()
		Phase.ROUND_START:
			_field.freeze_players()
			_field.set_kickoff()
			_phase_timer = _pre_round_time
		Phase.DURING_ROUND:
			_field.unfreeze_players()
		Phase.ROUND_END:
			_phase_timer = _post_goal_time
	_current_phase = phase

func init_game(s: GameSettings) -> void:
	_settings = s
	_field.init_players(s.players_settings)

func start_new_game() -> void:
	# reset game values
	_left_score = 0
	_right_score = 0
	_elapsed_time = 0.0

	# set initial ui values
	_ui.update_score(0, 0)
	_ui.update_game_timer(_settings.game_time)

	# set starting phase
	_set_phase(Phase.PRE_GAME)

#
# Signal calls
#

func _on_field_goal_scored(team: Game.Team) -> void:
	if _current_phase != Phase.DURING_ROUND: return
	# update scores
	if team == Game.Team.LEFT: _right_score += 1
	else: _left_score += 1
	_ui.update_score(_left_score, _right_score)

	_set_phase(Phase.ROUND_END)

#
# Editor functions
#

func _apply_editor_overrides() -> void:
	_settings = GameSettings.new()
	var temp = left_team_count
	for i in range(player_count):
		var p = Pufferfish.PlayerSettings.new()
		if (i % 2) == 0: p.input_id = "k1"
		else: p.input_id = "k2"
		p.id = i
		if temp > 0: p.team = Game.Team.LEFT
		else: p.team = Game.Team.RIGHT
		temp -= 1
		_settings.players_settings.append(p)
	init_game(_settings)
	start_new_game()

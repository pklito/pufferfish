extends Node

var game_settings: Game.GameSettings

@onready var _game: Game = $Game
@onready var _pause_menu = $CanvasLayer/PauseMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# connect signals
	_pause_menu.resume_pressed.connect(_resume)
	_pause_menu.exit_pressed.connect(_exit_game)

	# start the game
	_game.init_game(game_settings)
	_game.start_new_game()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"): _toggle_pause()

func _toggle_pause() -> void:
	if get_tree().paused: _resume()
	else: _pause()

func _pause() -> void:
	get_tree().paused = true
	_pause_menu.show()

func _resume() -> void:
	_pause_menu.hide()
	get_tree().paused = false

func _exit_game() -> void:
	# TODO: return to main menu
	get_tree().quit()

# TODO: check for controller disconnect and pause

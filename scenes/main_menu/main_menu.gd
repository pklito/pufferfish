extends Control

signal game_started(game_settings: Game.GameSettings)

@onready var _title_screen: Control = $TitleScreen
@onready var _game_setup_screen: Control = $GameSetup

func _ready() -> void:
	pass

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_play_pressed() -> void:
	_title_screen.visible = false
	_game_setup_screen.visible = true

func _connect_signals() -> void:
	_game_setup_screen.started.connect()

func _on_game_setup_start(game_settings: Game.GameSettings) -> void:
	game_started.emit(game_settings)


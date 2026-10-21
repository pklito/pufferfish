extends Control

signal game_started(game_settings: Game.GameSettings)

@onready var _title_screen: Control = $TitleScreen
@onready var _game_setup_screen: Control = $GameSetup

func _ready() -> void:
	_connect_signals()

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_play_pressed() -> void:
	# switch to game setup screen
	_title_screen.visible = false
	_title_screen.process_mode = Node.PROCESS_MODE_DISABLED
	_game_setup_screen.process_mode = Node.PROCESS_MODE_INHERIT
	_game_setup_screen.visible = true

func _connect_signals() -> void:
	_game_setup_screen.started.connect(_on_game_setup_start)

func _on_game_setup_start(game_settings: Game.GameSettings) -> void:
	game_started.emit(game_settings)


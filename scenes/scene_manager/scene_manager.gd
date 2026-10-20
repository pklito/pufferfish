extends Node

const GAME_MANAGER_SCENE: PackedScene = preload("res://scenes/game_manager/game_manager.tscn")

@onready var current_scene = $MainMenu

func _ready() -> void:
	current_scene.game_started.connect(_on_main_menu_game_start)

func _on_main_menu_game_start(settings: Game.GameSettings) -> void:
	current_scene.queue_free()
	current_scene = GAME_MANAGER_SCENE.instantiate()
	current_scene.settings = settings
	add_child(current_scene)

# TODO: when game_manager quits, load main menu again


extends Control

signal started(s: Game.GameSettings)

var _game_settings: Game.GameSettings = Game.GameSettings.new()

func _ready() -> void:
	pass # Replace with function body.

func _on_start_pressed() -> void:
	started.emit(_game_settings)


extends Control

signal resume_pressed
signal exit_pressed

func _ready() -> void:
	pass

func _on_exit_pressed() -> void:
	exit_pressed.emit()

func _on_resume_pressed() -> void:
	resume_pressed.emit()


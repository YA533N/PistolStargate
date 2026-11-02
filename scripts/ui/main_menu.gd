extends Control

const HUB_SCENE := "res://scenes/levels/hub.tscn"

@onready var _play_button: Button = %PlayButton


func _ready() -> void:
	_play_button.grab_focus()


func _on_play_pressed() -> void:
	GameState.reset_run()
	get_tree().change_scene_to_file(HUB_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()

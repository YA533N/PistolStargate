extends CanvasLayer
## Esc toggles pause. This node's process_mode is Always, so it still runs while the tree is paused.

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"

@onready var _resume_button: Button = %ResumeButton


func _ready() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	visible = paused
	if paused:
		_resume_button.grab_focus()


func _on_resume_pressed() -> void:
	_set_paused(false)


func _on_restart_pressed() -> void:
	_set_paused(false)
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	_set_paused(false)
	get_tree().change_scene_to_file(MAIN_MENU)


func _on_quit_pressed() -> void:
	get_tree().quit()

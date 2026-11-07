extends CanvasLayer
## Esc toggles pause. This node's process_mode is Always, so it still runs while the tree is paused.
## Shows the title art with Resume / Restart / Main Menu / Quit (see RowMenu).

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"

@onready var _menu: RowMenu = %Menu


func _ready() -> void:
	visible = false
	_menu.visible = false
	_menu.chosen.connect(_on_menu_chosen)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	visible = paused
	# Hidden with the layer too, so it ignores up/down/accept during play.
	_menu.visible = paused
	if paused:
		_menu.reset()


func _on_menu_chosen(index: int) -> void:
	match index:
		0:
			_set_paused(false)
		1:
			_set_paused(false)
			get_tree().reload_current_scene()
		2:
			_set_paused(false)
			get_tree().change_scene_to_file(MAIN_MENU)
		3:
			get_tree().quit()

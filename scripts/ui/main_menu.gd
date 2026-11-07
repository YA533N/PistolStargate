extends Control
## Title screen: the key art with a pulsing PRESS ANY BUTTON. Any key, mouse button or pad button brings
## up the menu (Play, Quit); see RowMenu.

const HUB_SCENE := "res://scenes/levels/hub.tscn"

@onready var _prompt: Label = %PressPrompt
@onready var _menu: RowMenu = %Menu

var _pulse: Tween


func _ready() -> void:
	_menu.visible = false
	_menu.chosen.connect(_on_menu_chosen)
	_pulse = create_tween().set_loops()
	_pulse.tween_property(_prompt, "modulate:a", 0.25, 0.8).set_trans(Tween.TRANS_SINE)
	_pulse.tween_property(_prompt, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)


func _unhandled_input(event: InputEvent) -> void:
	if _menu.visible or not _is_button_press(event):
		return
	get_viewport().set_input_as_handled()
	_show_menu()


func _is_button_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	return (event is InputEventMouseButton or event is InputEventJoypadButton) and event.pressed


func _show_menu() -> void:
	_pulse.kill()
	_prompt.visible = false
	_menu.visible = true
	_menu.modulate.a = 0.0
	create_tween().tween_property(_menu, "modulate:a", 1.0, 0.25)


func _on_menu_chosen(index: int) -> void:
	match index:
		0:
			GameState.reset_run()
			get_tree().change_scene_to_file(HUB_SCENE)
		1:
			get_tree().quit()

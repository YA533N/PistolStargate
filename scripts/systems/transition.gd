extends CanvasLayer
## Autoload "Transition": full-screen colour fades between scenes (portals, the Orange Trooper's teleport).

var _rect := ColorRect.new()
var _busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.color = Color(0, 0, 0, 0)
	add_child(_rect)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Fades to color, swaps the scene, then fades back in. Ignored while a change is already running.
func change_scene(path: String, color := Color.BLACK, fade_time := 0.45) -> void:
	if _busy:
		return
	_busy = true
	_rect.color = Color(color, 0.0)
	var fade_out := create_tween()
	fade_out.tween_property(_rect, "color:a", 1.0, fade_time)
	await fade_out.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	# Wait for the new scene to be in place before revealing it.
	await get_tree().process_frame
	await get_tree().process_frame
	var fade_in := create_tween()
	fade_in.tween_property(_rect, "color:a", 0.0, fade_time)
	await fade_in.finished
	_busy = false


## A quick full-screen flash without changing scene.
func flash(color: Color, duration := 0.4) -> void:
	_rect.color = Color(color, 0.8)
	create_tween().tween_property(_rect, "color:a", 0.0, duration)

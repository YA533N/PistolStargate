extends Node
## Autoload "CursorAnimator": the team's red crosshair as the mouse cursor everywhere (menus, pause, gameplay),
## animated by swapping between its two frames. The project setting display/mouse_cursor/custom_image holds
## frame 1, so the cursor is already there while the game starts.

const FRAMES: Array[Texture2D] = [
	preload("res://assets/textures/ui/cursor_1.png"),
	preload("res://assets/textures/ui/cursor_2.png"),
]
# Seconds each frame stays up, as timed in the Aseprite animation.
const DURATIONS: Array[float] = [1.0, 0.5]
# The centre of the cross, the pixel that clicks.
const HOTSPOT := Vector2(32, 32)

var _frame := 0
var _time := 0.0


func _ready() -> void:
	# Keeps animating while the tree is paused, so the pause menu's cursor moves too.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_show_frame()


func _process(delta: float) -> void:
	_time += delta
	if _time < DURATIONS[_frame]:
		return
	_time -= DURATIONS[_frame]
	_frame = (_frame + 1) % FRAMES.size()
	_show_frame()


func _show_frame() -> void:
	Input.set_custom_mouse_cursor(FRAMES[_frame], Input.CURSOR_ARROW, HOTSPOT)

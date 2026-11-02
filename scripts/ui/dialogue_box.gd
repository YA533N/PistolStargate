class_name DialogueBox
extends CanvasLayer
## Dialogue panel along the bottom of the screen, with typewriter text.
## Call start() with a speaker and lines. F (interact) shows the whole line, then moves to the next one.
## Emits finished after the last line is closed.

signal started
signal finished

## Characters revealed per second.
@export var reveal_speed := 45.0

@onready var _speaker_label: Label = %SpeakerLabel
@onready var _text_label: Label = %TextLabel
@onready var _continue_hint: Label = %ContinueHint

var _lines := PackedStringArray()
var _index := 0
var _revealed := 0.0


func _ready() -> void:
	add_to_group("dialogue_box")
	visible = false
	set_process(false)


func is_open() -> bool:
	return visible


func start(speaker: String, lines: PackedStringArray) -> void:
	if lines.is_empty():
		push_warning("DialogueBox.start() called with no lines.")
		return
	_speaker_label.text = speaker
	_lines = lines
	visible = true
	set_process(true)
	_show_line(0)
	started.emit()


func close() -> void:
	visible = false
	set_process(false)
	finished.emit()


func _process(delta: float) -> void:
	if not _is_line_done():
		_revealed += reveal_speed * delta
		_text_label.visible_characters = int(_revealed)
	_continue_hint.visible = _is_line_done()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	if not _is_line_done():
		_text_label.visible_characters = -1
	elif _index + 1 < _lines.size():
		_show_line(_index + 1)
	else:
		close()


func _show_line(index: int) -> void:
	_index = index
	_text_label.text = _lines[index]
	_text_label.visible_characters = 0
	_revealed = 0.0
	_continue_hint.visible = false
	_continue_hint.text = "[F] continue" if index + 1 < _lines.size() else "[F] close"


func _is_line_done() -> bool:
	return _text_label.visible_characters < 0 or _text_label.visible_characters >= _text_label.get_total_character_count()

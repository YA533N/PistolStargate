class_name DialogueBox
extends CanvasLayer
## Dialogue panel along the bottom of the screen, with typewriter text.
## Call start() with a speaker and lines. E (talk) shows the whole line, then moves to the next one.
## Emits finished after the last line is closed.
## ask() shows one line with answer buttons (click, or press 1/2/3) and emits choice_made with the index.

signal started
signal finished
signal choice_made(index: int)

## Characters revealed per second.
@export var reveal_speed := 45.0

@onready var _speaker_label: Label = %SpeakerLabel
@onready var _text_label: Label = %TextLabel
@onready var _continue_hint: Label = %ContinueHint
@onready var _choice_row: HBoxContainer = %ChoiceRow

var _lines := PackedStringArray()
var _index := 0
var _revealed := 0.0
## Answers for the current question; empty for normal lines.
var _choices := PackedStringArray()


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
	_choices = PackedStringArray()
	_choice_row.visible = false
	visible = true
	set_process(true)
	_show_line(0)
	started.emit()


## A question with answers. Await choice_made for the picked index.
func ask(speaker: String, question: String, options: PackedStringArray) -> void:
	start(speaker, PackedStringArray([question]))
	_choices = options


func close() -> void:
	visible = false
	set_process(false)
	_choice_row.visible = false
	finished.emit()


func _process(delta: float) -> void:
	if not _is_line_done():
		_revealed += reveal_speed * delta
		_text_label.visible_characters = int(_revealed)
	var waiting_for_answer := not _choices.is_empty()
	_continue_hint.visible = _is_line_done() and not waiting_for_answer
	if waiting_for_answer and _is_line_done() and not _choice_row.visible:
		_show_choices()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not _choices.is_empty() and _choice_row.visible:
		var key := event as InputEventKey
		if key and key.pressed and not key.echo:
			var index := key.physical_keycode - KEY_1
			if index >= 0 and index < _choices.size():
				get_viewport().set_input_as_handled()
				_pick(index)
		return
	if not event.is_action_pressed("talk"):
		return
	get_viewport().set_input_as_handled()
	if not _is_line_done():
		_text_label.visible_characters = -1
	elif not _choices.is_empty():
		return
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
	_continue_hint.text = "[E] continue" if index + 1 < _lines.size() else "[E] close"


func _show_choices() -> void:
	for child in _choice_row.get_children():
		child.queue_free()
	for i in _choices.size():
		var button := Button.new()
		button.text = "[%d]  %s" % [i + 1, _choices[i]]
		button.add_theme_font_size_override("font_size", 28)
		button.custom_minimum_size = Vector2(220, 56)
		button.pressed.connect(_pick.bind(i))
		_choice_row.add_child(button)
	_choice_row.visible = true
	(_choice_row.get_child(0) as Button).grab_focus.call_deferred()


func _pick(index: int) -> void:
	_choices = PackedStringArray()
	close()
	choice_made.emit(index)


func _is_line_done() -> bool:
	return _text_label.visible_characters < 0 or _text_label.visible_characters >= _text_label.get_total_character_count()

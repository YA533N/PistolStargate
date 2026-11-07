class_name RowMenu
extends VBoxContainer
## Menu options as full-width rows with right-aligned text, laid out like RUINER's menu but in cyan.
## The selected row gets a cyan bar with dark text. chosen is emitted when an option is picked.
## Mouse: hover to select, click to choose. Keys/pad: up/down to select, accept (Enter/Space) to choose.

signal chosen(index: int)

const CYAN := Color(0.64, 1.0, 0.96)
const DARK := Color(0.02, 0.05, 0.07)
const FONT := preload("res://assets/fonts/space.ttf")
const ROW_HEIGHT := 60.0
const RIGHT_MARGIN := 110.0

@export var options := PackedStringArray()
@export var font_size := 34

var _rows: Array[Row] = []
var _selected := 0


class Row:
	var root: Control
	var bar: ColorRect
	var label: Label


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 4)
	for i in options.size():
		_rows.append(_build_row(options[i], i))
	_refresh()


## Back to the first option (e.g. each time the pause menu opens).
func reset() -> void:
	_select(0)


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _rows.is_empty():
		return
	if event.is_action_pressed("ui_down"):
		_select(wrapi(_selected + 1, 0, _rows.size()))
	elif event.is_action_pressed("ui_up"):
		_select(wrapi(_selected - 1, 0, _rows.size()))
	elif event.is_action_pressed("ui_accept"):
		chosen.emit(_selected)
	else:
		return
	get_viewport().set_input_as_handled()


func _build_row(text: String, index: int) -> Row:
	var row := Row.new()
	row.root = Control.new()
	row.root.custom_minimum_size.y = ROW_HEIGHT
	add_child(row.root)
	row.root.mouse_entered.connect(_select.bind(index))
	row.root.gui_input.connect(_on_row_input.bind(index))

	row.bar = ColorRect.new()
	row.bar.color = CYAN
	row.bar.mouse_filter = MOUSE_FILTER_IGNORE
	row.bar.set_anchors_preset(PRESET_FULL_RECT)
	row.root.add_child(row.bar)

	row.label = Label.new()
	row.label.text = text.to_upper()
	row.label.add_theme_font_override("font", FONT)
	row.label.add_theme_font_size_override("font_size", font_size)
	row.label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.label.mouse_filter = MOUSE_FILTER_IGNORE
	row.label.set_anchors_preset(PRESET_FULL_RECT)
	row.label.offset_right = -RIGHT_MARGIN
	row.root.add_child(row.label)
	return row


func _on_row_input(event: InputEvent, index: int) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_select(index)
		chosen.emit(index)


func _select(index: int) -> void:
	_selected = index
	_refresh()


func _refresh() -> void:
	for i in _rows.size():
		var selected := i == _selected
		_rows[i].bar.visible = selected
		_rows[i].label.add_theme_color_override("font_color", DARK if selected else CYAN)

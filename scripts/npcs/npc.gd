class_name NPC
extends Node3D
## A character the player can talk to. When the player is inside TalkArea a "[F] Talk" prompt shows;
## pressing interact opens the DialogueBox with this NPC's lines and freezes the player until it closes.
## Expects children: Model (an imported character), TalkArea (Area3D) and Prompt (Label3D).

@export var speaker_name := "???"
@export var lines := PackedStringArray()
## Animation to loop on the model. Leave empty to use the model's first animation.
@export var idle_animation := ""
## Hold the animation's first frame and only move while talking. Off: loop it all the time.
@export var animate_only_while_talking := true
## Turn toward the player when a conversation starts.
@export var face_player := true

@onready var _model: Node3D = $Model
@onready var _talk_area: Area3D = $TalkArea
@onready var _prompt: Label3D = $Prompt

## The player inside the talk area, or null.
var _player_in_range: Player
## The player currently in a conversation with this NPC, or null.
var _talking_to: Player
var _animation_player: AnimationPlayer


func _ready() -> void:
	_prompt.visible = false
	_talk_area.body_entered.connect(_on_body_entered)
	_talk_area.body_exited.connect(_on_body_exited)
	_setup_animation()


func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range == null or _talking_to != null or not event.is_action_pressed("interact"):
		return
	var box := get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	if box == null:
		push_warning("NPC '%s' has no DialogueBox in the scene to talk through." % speaker_name)
		return
	if box.is_open():
		return
	get_viewport().set_input_as_handled()
	_start_talking(box)


func _start_talking(box: DialogueBox) -> void:
	_talking_to = _player_in_range
	_talking_to.input_enabled = false
	_prompt.visible = false
	if face_player:
		_turn_toward(_talking_to.global_position)
	if animate_only_while_talking and _animation_player:
		_animation_player.play()
	box.finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	box.start(speaker_name, lines)


func _on_dialogue_finished() -> void:
	_talking_to.input_enabled = true
	_talking_to = null
	_prompt.visible = _player_in_range != null
	if animate_only_while_talking and _animation_player:
		_hold_first_frame()


func _turn_toward(target: Vector3) -> void:
	var offset := target - global_position
	# Imported characters face +Z, so the yaw that points them at the target is atan2(x, z).
	var target_yaw := atan2(offset.x, offset.z)
	var start_yaw := rotation.y
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void: rotation.y = lerp_angle(start_yaw, target_yaw, t), 0.0, 1.0, 0.25)


func _setup_animation() -> void:
	_animation_player = _model.find_child("AnimationPlayer") as AnimationPlayer
	if _animation_player == null:
		return
	var animation := idle_animation
	if animation.is_empty() and not _animation_player.get_animation_list().is_empty():
		animation = _animation_player.get_animation_list()[0]
	if not _animation_player.has_animation(animation):
		push_warning("NPC '%s' has no animation called '%s'." % [speaker_name, animation])
		_animation_player = null
		return
	_animation_player.play(animation)
	if animate_only_while_talking:
		_hold_first_frame()


## Freezes the model on the animation's first frame (a standing pose, not the T-pose).
func _hold_first_frame() -> void:
	_animation_player.seek(0.0, true)
	_animation_player.pause()


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		_player_in_range = body
		_prompt.visible = _talking_to == null


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		_prompt.visible = false

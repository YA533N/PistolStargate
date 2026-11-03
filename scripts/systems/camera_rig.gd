class_name CameraRig
extends Node3D
## Isometric camera that follows a target with smoothing, and shakes on big hits (Effects.shake()).
## The fixed angle (45 degree yaw, 35.264 degree pitch, orthographic) lives on the
## Yaw/Pitch/Camera3D children in camera_rig.tscn.

@export var target: Node3D
## Higher is snappier. Frame-rate independent.
@export var follow_sharpness := 10.0
## Pulls the camera this fraction of the way toward the player's aim point,
## so the player sees more of the screen in the direction they're shooting.
@export_range(0.0, 0.5) var aim_lead := 0.15
## Largest shake offset in metres, and how fast a shake dies down (per second).
@export var max_shake := 0.6
@export var shake_decay := 2.5

@onready var _camera: Camera3D = find_child("Camera3D") as Camera3D

var _trauma := 0.0


func _ready() -> void:
	add_to_group("camera_rig")
	if target:
		global_position = target.global_position


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var goal := target.global_position
	var player := target as Player
	if player and aim_lead > 0.0:
		goal += (player.aim_point - goal) * aim_lead
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_sharpness * delta))


func _process(delta: float) -> void:
	if _camera == null:
		return
	_trauma = maxf(_trauma - shake_decay * delta, 0.0)
	var amount := _trauma * _trauma * max_shake
	_camera.h_offset = randf_range(-amount, amount)
	_camera.v_offset = randf_range(-amount, amount)


## strength 0-1; shakes add up to a maximum of 1.
func shake(strength: float) -> void:
	_trauma = minf(_trauma + strength, 1.0)

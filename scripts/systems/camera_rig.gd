class_name CameraRig
extends Node3D
## Isometric camera that follows a target with smoothing.
## The fixed angle (45 degree yaw, 35.264 degree pitch, orthographic) lives on the
## Yaw/Pitch/Camera3D children in camera_rig.tscn.

@export var target: Node3D
## Higher is snappier. Frame-rate independent.
@export var follow_sharpness := 10.0
## Pulls the camera this fraction of the way toward the player's aim point,
## so the player sees more of the screen in the direction they're shooting.
@export_range(0.0, 0.5) var aim_lead := 0.15


func _ready() -> void:
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

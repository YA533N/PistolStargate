class_name Weapon
extends Node3D
## A gun the player holds. try_fire() spawns a projectile from Muzzle toward a target point,
## limited by fire_rate. Values are placeholders until weapon balance is set in the GDD.
## Expects a Marker3D child called Muzzle at the barrel tip.

signal fired

@export var projectile_scene: PackedScene
## Shots per second while the button is held.
@export var fire_rate := 6.0
@export var damage := 10
## Metres per second.
@export var projectile_speed := 30.0
## Closer than this, the target is behind or beside the muzzle, so fire straight ahead instead.
@export var min_aim_distance := 1.5

@onready var _muzzle: Marker3D = $Muzzle

var _cooldown := 0.0


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)


## Fires toward target (flattened to the muzzle's height). Returns false while on cooldown.
func try_fire(target: Vector3) -> bool:
	if _cooldown > 0.0 or projectile_scene == null:
		return false
	var origin := _muzzle.global_position
	var direction := target - origin
	direction.y = 0.0
	if direction.length() < min_aim_distance:
		direction = -global_basis.z
		direction.y = 0.0
	var projectile := projectile_scene.instantiate() as Projectile
	get_tree().current_scene.add_child(projectile)
	projectile.launch(origin, direction.normalized(), projectile_speed, damage)
	_cooldown = 1.0 / fire_rate
	fired.emit()
	return true

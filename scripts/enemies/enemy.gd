class_name Enemy
extends CharacterBody3D
## Base for everything the player can kill: health, gravity, loot and kill credit.
## tier decides what the Infinite Pistol does: NORMAL enemies die in one shot and spill a jackpot;
## ELITE and BOSS enemies only take its elite_damage.
## Expects a Health child. Put enemies on the "enemies" physics layer (3).

signal killed(enemy: Enemy)

enum Tier { NORMAL, ELITE, BOSS }

@export var display_name := "Enemy"
@export var tier := Tier.NORMAL
@export var gravity := 24.0

@export_group("Loot")
## Cash dropped on a normal kill, from x to y.
@export var money_drop := Vector2i(3, 8)
@export_range(0.0, 1.0) var ammo_drop_chance := 0.35
@export_range(0.0, 1.0) var health_drop_chance := 0.15
@export_range(0.0, 1.0) var weapon_drop_chance := 0.1
## Always part of the Infinite Pistol jackpot (the tutorial chicken uses this). Random weapons fill the rest.
@export var jackpot_weapons: Array[WeaponData] = []

@onready var health: Health = $Health

## Set by Combat when the Infinite Pistol lands the killing shot.
var killed_by_infinite_pistol := false


func _ready() -> void:
	add_to_group("enemies")
	health.show_damage_numbers = true
	health.died.connect(_on_died)


func is_dead() -> bool:
	return health.is_dead()


func get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = minf(velocity.y, 0.0)
	else:
		velocity.y -= gravity * delta


## Turns smoothly toward direction. Imported characters face +Z, so the yaw is atan2(x, z).
func face(direction: Vector3, delta: float, sharpness := 10.0) -> void:
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return
	rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-sharpness * delta))


func _on_died() -> void:
	remove_from_group("enemies")
	set_deferred("collision_layer", 0)
	GameState.enemy_killed.emit(self)
	if killed_by_infinite_pistol:
		Loot.jackpot(self)
	else:
		Loot.normal_drop(self)
	killed.emit(self)
	_die()


## Default death: a puff and gone. Bigger enemies override this to play an animation.
func _die() -> void:
	Effects.flash(self, global_position + Vector3.UP * 0.6, Color(1, 0.95, 0.8), 1.2, 0.3)
	queue_free()

class_name Health
extends Node
## Reusable hit points. Add as a child of the player or any enemy and listen to its signals.

signal changed(current: int, maximum: int)
signal died

@export var max_health := 100

var current := 0
## Set by the owner, e.g. during a dash's invincibility frames.
var invulnerable := false


func _ready() -> void:
	current = max_health


func is_dead() -> bool:
	return current <= 0


func take_damage(amount: int) -> void:
	if invulnerable or is_dead() or amount <= 0:
		return
	current = maxi(current - amount, 0)
	changed.emit(current, max_health)
	if current == 0:
		died.emit()


func heal(amount: int) -> void:
	if is_dead() or amount <= 0:
		return
	current = mini(current + amount, max_health)
	changed.emit(current, max_health)

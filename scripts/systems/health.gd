class_name Health
extends Node
## Reusable hit points. Add as a child of the player or any enemy and listen to its signals.
## Also runs poison damage-over-time and can pop up floating damage numbers.

signal changed(current: int, maximum: int)
signal damaged(amount: int, kind: Kind)
signal died

## What caused the damage, so damage numbers can be coloured.
enum Kind { NORMAL, POISON, EXPLOSION, CHAIN, INSTAKILL }

const KIND_COLORS := {
	Kind.NORMAL: Color(1, 1, 1),
	Kind.POISON: Color(0.45, 1, 0.3),
	Kind.EXPLOSION: Color(1, 0.6, 0.2),
	Kind.CHAIN: Color(0.45, 0.85, 1),
	Kind.INSTAKILL: Color(0.5, 1, 1),
}
const POISON_TICK := 0.5

@export var max_health := 100
## Floating numbers above the owner when it takes damage (on for enemies).
@export var show_damage_numbers := false
## Height of the damage numbers above the owner's origin.
@export var number_height := 1.8

var current := 0
## Set by the owner, e.g. during a dash's invincibility frames.
var invulnerable := false
## Debug cheat: ignore all damage.
var infinite_health := false

var _poison_dps := 0
var _poison_time_left := 0.0
var _poison_tick_left := 0.0


func _ready() -> void:
	current = max_health
	set_process(false)


func is_dead() -> bool:
	return current <= 0


func is_poisoned() -> bool:
	return _poison_time_left > 0.0


func take_damage(amount: int, kind := Kind.NORMAL) -> void:
	if invulnerable or infinite_health or is_dead() or amount <= 0:
		return
	current = maxi(current - amount, 0)
	changed.emit(current, max_health)
	damaged.emit(amount, kind)
	if show_damage_numbers:
		_show_number(amount, kind)
	if current == 0:
		_poison_time_left = 0.0
		died.emit()


func heal(amount: int) -> void:
	if is_dead() or amount <= 0:
		return
	current = mini(current + amount, max_health)
	changed.emit(current, max_health)


## Fills health back up without any effects (training dummy, cheats).
func reset() -> void:
	current = max_health
	changed.emit(current, max_health)


## Poison deals dps every second for duration. A new dose refreshes the timer and keeps the stronger dps.
func apply_poison(dps: int, duration: float) -> void:
	if is_dead() or dps <= 0 or duration <= 0.0:
		return
	_poison_dps = maxi(_poison_dps, dps) if is_poisoned() else dps
	_poison_time_left = maxf(_poison_time_left, duration)
	if not is_processing():
		_poison_tick_left = POISON_TICK
	set_process(true)


func _process(delta: float) -> void:
	_poison_time_left -= delta
	_poison_tick_left -= delta
	if _poison_tick_left <= 0.0:
		_poison_tick_left += POISON_TICK
		take_damage(maxi(1, roundi(_poison_dps * POISON_TICK)), Kind.POISON)
	if _poison_time_left <= 0.0 or is_dead():
		_poison_time_left = 0.0
		set_process(false)


func _show_number(amount: int, kind: Kind) -> void:
	var body := get_parent() as Node3D
	if body == null:
		return
	var text := "INSTAKILL!" if kind == Kind.INSTAKILL else str(amount)
	var size := 1.5 if kind == Kind.INSTAKILL else (0.8 if kind == Kind.POISON else 1.0)
	Effects.float_text(self, body.global_position + Vector3.UP * number_height, text, KIND_COLORS[kind], size)

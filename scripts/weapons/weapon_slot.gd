class_name WeaponSlot
extends RefCounted
## One weapon the player owns (or one lying on the floor): which weapon and how much ammo is left.

var data: WeaponData
var ammo := 0


## ammo_left < 0 means a full load.
func _init(weapon: WeaponData = null, ammo_left := -1) -> void:
	data = weapon
	if weapon:
		ammo = weapon.max_ammo if ammo_left < 0 else mini(ammo_left, weapon.max_ammo)


func is_out_of_ammo() -> bool:
	return ammo < data.ammo_per_shot


func is_full() -> bool:
	return ammo >= data.max_ammo


## Adds a share of the weapon's maximum ammo. Returns true if anything was added.
func refill(fraction: float) -> bool:
	if is_full():
		return false
	ammo = mini(data.max_ammo, ammo + maxi(1, ceili(data.max_ammo * fraction)))
	return true


func to_dict() -> Dictionary:
	return {"id": String(data.id), "ammo": ammo}


static func from_dict(d: Dictionary) -> WeaponSlot:
	var weapon := WeaponLibrary.find(StringName(d.get("id", "")))
	if weapon == null:
		return null
	return WeaponSlot.new(weapon, int(d.get("ammo", -1)))

class_name WeaponLibrary
## Every weapon in the game. To add one, make a WeaponData .tres in resources/weapons/ and list it in ALL.

const INFINITE_PISTOL: WeaponData = preload("res://resources/weapons/infinite_pistol.tres")

const ALL: Array[WeaponData] = [
	preload("res://resources/weapons/capper.tres"),
	preload("res://resources/weapons/scifi_rifle.tres"),
	preload("res://resources/weapons/cyber_smg.tres"),
	preload("res://resources/weapons/toxic.tres"),
	preload("res://resources/weapons/space_gun.tres"),
	preload("res://resources/weapons/plasma.tres"),
	preload("res://resources/weapons/sniper.tres"),
	preload("res://resources/weapons/collector.tres"),
	preload("res://resources/weapons/ares_lmg.tres"),
	preload("res://resources/weapons/railgun.tres"),
	preload("res://resources/weapons/arc_charger.tres"),
	preload("res://resources/weapons/toy_gun.tres"),
	INFINITE_PISTOL,
]


static func find(id: StringName) -> WeaponData:
	for weapon in ALL:
		if weapon.id == id:
			return weapon
	return null


## Everything except the Infinite Pistol, sorted from common to legendary.
static func droppable() -> Array[WeaponData]:
	var result: Array[WeaponData] = []
	for weapon in ALL:
		if weapon.rarity != Rarity.Tier.INFINITE:
			result.append(weapon)
	result.sort_custom(func(a: WeaponData, b: WeaponData) -> bool: return a.rarity < b.rarity)
	return result


## A random weapon, picked by rarity weight (Rarity.DROP_WEIGHTS), at least min_tier.
static func random_drop(min_tier := Rarity.Tier.COMMON) -> WeaponData:
	var pool := droppable()
	var total := 0.0
	for weapon in pool:
		if weapon.rarity >= min_tier:
			total += _weight(weapon, pool)
	var roll := randf() * total
	for weapon in pool:
		if weapon.rarity < min_tier:
			continue
		roll -= _weight(weapon, pool)
		if roll <= 0.0:
			return weapon
	return pool.back()


## A tier's weight is shared between the weapons in it, so adding guns doesn't change tier odds.
static func _weight(weapon: WeaponData, pool: Array[WeaponData]) -> float:
	var same_tier := pool.filter(func(w: WeaponData) -> bool: return w.rarity == weapon.rarity).size()
	return Rarity.DROP_WEIGHTS[weapon.rarity] / maxf(same_tier, 1.0)

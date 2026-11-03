class_name Loot
## Spawns pickups: what enemies drop, the Infinite Pistol's jackpot, weapons the player drops,
## and weapons spawned by the cheat menu. Pickups burst out in an arc and land on the floor.

const WEAPON_PICKUP := preload("res://scenes/pickups/weapon_pickup.tscn")
const LOOT_PICKUP := preload("res://scenes/pickups/loot_pickup.tscn")


static func spawn_weapon(context: Node3D, slot: WeaponSlot, from: Vector3, to: Vector3) -> WeaponPickup:
	var pickup := WEAPON_PICKUP.instantiate() as WeaponPickup
	pickup.slot = slot
	_root(context).add_child(pickup)
	pickup.launch(from, to)
	return pickup


static func spawn_item(context: Node3D, kind: LootPickup.Kind, amount: int, from: Vector3, to: Vector3) -> LootPickup:
	var pickup := LOOT_PICKUP.instantiate() as LootPickup
	pickup.kind = kind
	pickup.amount = amount
	_root(context).add_child(pickup)
	pickup.launch(from, to)
	return pickup


## What the Infinite Pistol makes a normal enemy spill: 2-3 weapons (jackpot_weapons first, random
## ones for the rest), ammo, a pile of cash and some health.
static func jackpot(enemy: Enemy) -> void:
	var origin := enemy.global_position
	var weapons: Array[WeaponData] = enemy.jackpot_weapons.duplicate()
	var count := maxi(weapons.size(), randi_range(2, 3))
	while weapons.size() < count:
		weapons.append(WeaponLibrary.random_drop())
	var start_angle := randf() * TAU
	for i in weapons.size():
		var angle := start_angle + TAU * i / weapons.size()
		spawn_weapon(enemy, WeaponSlot.new(weapons[i]), origin + Vector3.UP, landing_spot(enemy, origin, 2.6, 3.4, angle))
	for i in 2:
		spawn_item(enemy, LootPickup.Kind.AMMO, 0, origin + Vector3.UP, landing_spot(enemy, origin, 1.2, 2.2))
	for i in 4:
		spawn_item(enemy, LootPickup.Kind.MONEY, randi_range(8, 15), origin + Vector3.UP, landing_spot(enemy, origin, 1.0, 2.5))
	spawn_item(enemy, LootPickup.Kind.HEALTH, 25, origin + Vector3.UP, landing_spot(enemy, origin, 1.0, 2.0))
	Effects.flash(enemy, origin + Vector3.UP, Rarity.color(Rarity.Tier.INFINITE), 3.0, 0.5)
	Effects.shake(enemy, 0.4)
	enemy.get_tree().call_group("hud", "show_message", "JACKPOT!", 1.5)


## A normal kill: some cash, maybe ammo, health or a weapon (chances set on the enemy).
static func normal_drop(enemy: Enemy) -> void:
	var origin := enemy.global_position
	var cash := randi_range(enemy.money_drop.x, enemy.money_drop.y)
	if cash > 0:
		spawn_item(enemy, LootPickup.Kind.MONEY, cash, origin + Vector3.UP, landing_spot(enemy, origin, 0.5, 1.5))
	if randf() < enemy.ammo_drop_chance:
		spawn_item(enemy, LootPickup.Kind.AMMO, 0, origin + Vector3.UP, landing_spot(enemy, origin, 0.5, 1.5))
	if randf() < enemy.health_drop_chance:
		spawn_item(enemy, LootPickup.Kind.HEALTH, 15, origin + Vector3.UP, landing_spot(enemy, origin, 0.5, 1.5))
	if randf() < enemy.weapon_drop_chance:
		spawn_weapon(enemy, WeaponSlot.new(WeaponLibrary.random_drop()), origin + Vector3.UP, landing_spot(enemy, origin, 1.5, 2.5))


## A point on the floor near origin, min to max metres away (at angle, or a random one),
## pulled back so it doesn't end up inside or behind a wall.
static func landing_spot(context: Node3D, origin: Vector3, min_distance: float, max_distance: float, angle := NAN) -> Vector3:
	var space := context.get_world_3d().direct_space_state
	if is_nan(angle):
		angle = randf() * TAU
	var start := origin + Vector3.UP * 0.5
	var direction := Vector3(cos(angle), 0.0, sin(angle))
	var target := start + direction * randf_range(min_distance, max_distance)
	var wall := space.intersect_ray(PhysicsRayQueryParameters3D.create(start, target, 1))
	if not wall.is_empty():
		target = start + direction * maxf(start.distance_to(wall.position) - 0.7, 0.0)
	var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(target + Vector3.UP * 2.0, target + Vector3.DOWN * 10.0, 1))
	target.y = floor_hit.position.y if not floor_hit.is_empty() else origin.y
	return target


static func _root(context: Node) -> Node:
	var tree := context.get_tree()
	return tree.current_scene if tree.current_scene else tree.root

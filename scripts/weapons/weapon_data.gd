class_name WeaponData
extends Resource
## One kind of weapon: its model, rarity, card text and how it shoots.
## Every weapon is a .tres in resources/weapons/ and is listed in WeaponLibrary.
## A weapon the player actually carries is a WeaponSlot (this data plus the ammo left).

@export var id := &""
@export var display_name := "Weapon"
## Shown on the card under the name, e.g. "SMG" or "Railgun".
@export var weapon_type := "Pistol"
@export var rarity: Rarity.Tier = Rarity.Tier.COMMON
## Item level printed on the card (flavour, like Borderlands).
@export var level := 1
## What the weapon does, in one or two sentences.
@export_multiline var description := ""
## The red joke line at the bottom of the card.
@export var flavor_text := ""

@export_group("Model")
@export var model: PackedScene
@export var model_scale := 1.0
@export var model_rotation_degrees := Vector3.ZERO
## Moves the model inside the hand. The imported guns are centred on their bounding box.
@export var hold_offset := Vector3(0, 0, -0.12)
## Barrel tip, in the same space as hold_offset. Zero means "front of the model's bounds".
@export var muzzle_position := Vector3.ZERO

@export_group("Firing")
## Held trigger keeps firing. Off: one shot per click.
@export var automatic := false
## Shots per second.
@export var fire_rate := 4.0
## Spin-up guns climb from fire_rate to this while the trigger stays held. 0 turns it off.
@export var max_fire_rate := 0.0
@export var spin_up_time := 0.0
@export var damage := 10
## Projectiles per shot (shotguns).
@export var pellets := 1
## Total cone width in degrees.
@export var spread_degrees := 0.0
## Metres per second.
@export var projectile_speed := 30.0
@export var projectile_size := 0.15
@export var projectile_color := Color(1, 1, 1)
## Metres a projectile flies before it fizzles.
@export var projectile_range := 40.0
## Ammo a freshly found copy of this weapon carries, and the most it can hold.
@export var max_ammo := 60
@export var ammo_per_shot := 1

@export_group("Special effects")
## Enemies a projectile passes through before stopping. -1 = all of them.
@export var pierce := 0
## Times a projectile ricochets off walls.
@export var bounces := 0
@export var explosion_radius := 0.0
@export var explosion_damage := 0
## Poison damage per second and how long it lasts. Hitting again refreshes it.
@export var poison_dps := 0
@export var poison_duration := 0.0
## Lightning jumps to this many extra enemies near the one hit.
@export var chain_count := 0
@export var chain_range := 6.0
@export_range(0.0, 1.0) var chain_damage_factor := 0.6
## How fast projectiles turn toward the nearest enemy, in radians per second. 0 = no homing.
@export var homing_turn_rate := 0.0
## Instant beam instead of a projectile (railgun).
@export var hitscan := false

@export_group("Infinite Pistol")
## Normal-tier enemies die in one hit and drop a jackpot of loot.
@export var instant_kill_normal := false
## What it deals to elites and bosses instead, since they can't be one-shot.
@export var elite_damage := 0
## Kills (with other weapons) that earn the next shot. 0 means it uses normal ammo.
@export var kills_per_charge := 0
## A shot that hits no enemy goes back into the chamber.
@export var refund_on_miss := false


## Damage of one trigger pull, counting every pellet.
func damage_per_shot() -> int:
	return damage * pellets + explosion_damage


func accuracy_percent() -> int:
	return clampi(roundi(100.0 - spread_degrees * 2.0), 5, 100)


func lifetime() -> float:
	return projectile_range / maxf(projectile_speed, 0.1)


## The model, scaled and turned for the hand. The barrel points along -Z.
func build_model() -> Node3D:
	var holder := Node3D.new()
	holder.name = "Model"
	if model:
		var inst := model.instantiate() as Node3D
		inst.rotation_degrees = model_rotation_degrees
		inst.scale = Vector3.ONE * model_scale
		inst.position = hold_offset
		holder.add_child(inst)
	return holder


## Barrel tip in build_model()'s space.
func muzzle_in(model_root: Node3D) -> Vector3:
	if muzzle_position != Vector3.ZERO:
		return muzzle_position
	var bounds := mesh_bounds(model_root)
	return Vector3(bounds.get_center().x, bounds.position.y + bounds.size.y * 0.72, bounds.position.z)


## Bounding box of every mesh under root, in root's space. Works before root is in the tree.
static func mesh_bounds(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		var to_root := Transform3D.IDENTITY
		var walker: Node = mesh_instance
		while walker != root and walker is Node3D:
			to_root = (walker as Node3D).transform * to_root
			walker = walker.get_parent()
		var box := to_root * mesh_instance.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result

extends Node3D
## The Proving Grounds: the tutorial arena the Orange Trooper teleports the player to from the hub.
##   1. He hands over the Infinite Pistol and asks if you understand that you must be merciless.
##   2. A chicken appears. You shoot it; the Infinite Pistol makes it spill weapons, ammo and cash.
##   3. The pistol is now empty, so you grab the chicken's weapons for "the true test":
##      THE FIRST DESCENDANT drops in. Spike traps and low walls in the arena teach "keep moving" and jumping.
##   4. Beat it and the exit portal back to the hub opens.
## Dying during the boss fight restarts at the boss with the chicken's weapons back on the floor.

const CHICKEN := preload("res://scenes/enemies/chicken.tscn")
const FIRST_DESCENDANT := preload("res://scenes/enemies/first_descendant.tscn")
## What the chicken always drops, so the boss fight is winnable: an SMG, an explosive and a sniper.
const TUTORIAL_WEAPONS: Array[WeaponData] = [
	preload("res://resources/weapons/cyber_smg.tres"),
	preload("res://resources/weapons/plasma.tres"),
	preload("res://resources/weapons/sniper.tres"),
]
const TROOPER_COLOR := Color(1, 0.6, 0.2)

@onready var _player: Player = $Player
@onready var _trooper: NPC = $OrangeTrooper
@onready var _chicken_spawn: Marker3D = $ChickenSpawn
@onready var _boss_spawn: Marker3D = $BossSpawn
@onready var _exit_portal: Portal = $ExitPortal


func _ready() -> void:
	_set_portal_open(false)
	if GameState.proving_grounds_checkpoint == "boss":
		_restart_at_boss.call_deferred()
	else:
		_intro.call_deferred()


func _intro() -> void:
	_player.arsenal.clear()
	_player.input_enabled = false
	await _wait(0.9)
	await _trooper.say(PackedStringArray([
		"Welcome to the Proving Grounds, human.",
		"Don't look so nervous. This is the nice part.",
		"Here. Take this.",
	]))
	_player.arsenal.give_infinite_pistol(true)
	Effects.flash(self, _player.global_position + Vector3.UP, Rarity.color(Rarity.Tier.INFINITE), 2.0, 0.5)
	_message("RECEIVED: THE INFINITE PISTOL", 2.5)
	await _wait(1.4)
	await _trooper.say(PackedStringArray([
		"That's the Infinite Pistol. One shot kills any normal creature instantly...",
		"...and whatever it kills spills everything it was carrying. Weapons. Ammo. Cash.",
		"Now. To get free, you have to be merciless.",
	]))
	var answer := await _trooper.ask("Do you understand?", PackedStringArray(["Yes.", "No."]))
	while answer == 1:
		await _trooper.say(PackedStringArray(["...", "Wrong answer. Let's try that again."]))
		answer = await _trooper.ask("Do you understand?", PackedStringArray(["Yes.", "No."]))
	await _trooper.say(PackedStringArray(["Good."]))

	var chicken := _spawn_chicken()
	await _wait(1.0)
	await _trooper.say(PackedStringArray([
		"You have to kill that chicken.",
		"Now.",
		"It didn't do anything to you. It doesn't matter. Kill it.",
	]))
	_player.input_enabled = true
	await chicken.killed
	await _wait(1.8)
	_player.input_enabled = false
	await _trooper.say(PackedStringArray([
		"...See that? It spilled everything it had.",
		"That's how it works in here. Every life the Infinite Pistol takes pays out.",
		"But it's empty now. It only recharges after you kill a few things with other guns.",
		"So grab those weapons off the floor. Walk up to one and press E. Fast hands live longer.",
		"Now you're ready for the true test.",
	]))
	GameState.proving_grounds_checkpoint = "boss"
	await _trooper.say(PackedStringArray(["I'll be watching. From somewhere very, very safe."]))
	_set_trooper_present(false)
	await _wait(0.8)
	_start_boss_fight()


func _restart_at_boss() -> void:
	_set_trooper_present(false)
	_player.arsenal.clear()
	_player.arsenal.give_infinite_pistol(false)
	for i in TUTORIAL_WEAPONS.size():
		var angle := TAU * i / TUTORIAL_WEAPONS.size()
		Loot.spawn_weapon(self, WeaponSlot.new(TUTORIAL_WEAPONS[i]), _chicken_spawn.global_position + Vector3.UP,
			Loot.landing_spot(_player, _chicken_spawn.global_position, 2.5, 3.0, angle))
	_message("Round two. Grab the guns!", 2.5)
	await _wait(2.5)
	_start_boss_fight()


func _start_boss_fight() -> void:
	_player.input_enabled = true
	var boss := FIRST_DESCENDANT.instantiate() as FirstDescendant
	add_child(boss)
	boss.global_position = _boss_spawn.global_position + Vector3.UP * 14.0
	_message("THE FIRST DESCENDANT", 2.5)
	await boss.killed
	_on_boss_defeated()


func _on_boss_defeated() -> void:
	GameState.proving_grounds_checkpoint = ""
	GameState.proving_grounds_done = true
	_message("PROVING GROUNDS CLEARED", 3.0)
	await _wait(3.5)
	_trooper.global_position = Loot.landing_spot(_player, _player.global_position, 2.5, 2.5)
	_set_trooper_present(true)
	_player.input_enabled = false
	await _trooper.say(PackedStringArray([
		"Hm. Not bad, human. Not bad at all.",
		"Keep the Infinite Pistol. Feed it kills and it'll feed you guns.",
		"The portal's open. Go back to the hub. The arena will be waiting.",
	]))
	_player.input_enabled = true
	_set_portal_open(true)


func _spawn_chicken() -> Chicken:
	var chicken := CHICKEN.instantiate() as Chicken
	chicken.jackpot_weapons = TUTORIAL_WEAPONS.duplicate()
	add_child(chicken)
	chicken.global_position = _chicken_spawn.global_position
	chicken.rotation.y = PI
	Effects.flash(self, chicken.global_position + Vector3.UP * 0.5, Color(1, 1, 1), 1.5, 0.4)
	return chicken


## The trooper teleports in or out with a flash. Hidden, he can't be bumped into or shot.
func _set_trooper_present(present: bool) -> void:
	Effects.flash(self, _trooper.global_position + Vector3.UP, TROOPER_COLOR, 2.0, 0.4)
	_trooper.visible = present
	# The trooper scene's root is a StaticBody3D.
	_trooper.set("collision_layer", 1 if present else 0)


func _set_portal_open(open: bool) -> void:
	_exit_portal.visible = open
	_exit_portal.set_deferred("monitoring", open)
	if open:
		Effects.flash(self, _exit_portal.global_position + Vector3.UP * 2.0, Color(0.6, 0.9, 1), 3.0, 0.6)


func _message(text: String, duration: float) -> void:
	get_tree().call_group("hud", "show_message", text, duration)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

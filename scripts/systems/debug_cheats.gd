extends Node
## Autoload "DebugCheats": test keys for playtesting (GDD 20.7). Disabled in release exports.
##   F1  hurt the player for 10
##   F2  heal the player for 25
##   F3  add 50 weapon currency and 10 relic currency
##   F4  weapon test menu: equip or spawn any weapon, spawn enemies and a training dummy (see CheatMenu)
##   F5  spawn a random weapon on the floor in front of the player
##   F6  spawn a training dummy
##   F7  give the Infinite Pistol, or recharge it
##   F8  refill all ammo

var _menu: CheatMenu


func _ready() -> void:
	if not OS.is_debug_build():
		set_process_unhandled_input(false)
		return
	# Keeps working while the game is paused, so F4 can close the menu again.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_menu = CheatMenu.new()
	add_child(_menu)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if key.physical_keycode == KEY_F4:
		_menu.toggle()
		get_viewport().set_input_as_handled()
		return
	if player == null or get_tree().paused:
		return
	match key.physical_keycode:
		KEY_F1:
			player.health.take_damage(10)
		KEY_F2:
			player.health.heal(25)
		KEY_F3:
			GameState.add_currency(50, 10)
		KEY_F5:
			_menu.spawn_weapon(WeaponLibrary.random_drop())
		KEY_F6:
			_menu.spawn_enemy(CheatMenu.DUMMY)
		KEY_F7:
			_menu.charge_pistol()
		KEY_F8:
			player.arsenal.refill_ammo(1.0)

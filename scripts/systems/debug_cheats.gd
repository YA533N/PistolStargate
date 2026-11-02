extends Node
## Autoload "DebugCheats": test keys for playtesting (GDD 20.7). Disabled in release exports.
##   F1  hurt the player for 10
##   F2  heal the player for 25
##   F3  add 50 weapon currency and 10 relic currency


func _ready() -> void:
	if not OS.is_debug_build():
		set_process_unhandled_input(false)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	match key.physical_keycode:
		KEY_F1:
			if player:
				player.health.take_damage(10)
		KEY_F2:
			if player:
				player.health.heal(25)
		KEY_F3:
			GameState.add_currency(50, 10)

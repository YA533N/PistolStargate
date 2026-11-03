class_name CheatMenu
extends CanvasLayer
## Weapon test menu (debug builds only, opened with F4 by DebugCheats). Lists every weapon by rarity with
## buttons to equip it straight into your hands or spawn it on the floor, plus test tools: training dummy,
## enemies, ammo, the Infinite Pistol and a loot jackpot. The game pauses while it is open.

const DUMMY := preload("res://scenes/enemies/training_dummy.tscn")
const CHICKEN := preload("res://scenes/enemies/chicken.tscn")
const FIRST_DESCENDANT := preload("res://scenes/enemies/first_descendant.tscn")

var _health_button: Button


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func toggle() -> void:
	if visible:
		close()
	# Not over the pause menu: closing would unpause the game behind it.
	elif _player() and not get_tree().paused:
		visible = true
		get_tree().paused = true
		_refresh_health_label()


func close() -> void:
	visible = false
	get_tree().paused = false


## _input, not _unhandled_input: the level's PauseMenu also takes Esc in _unhandled_input and gets it first,
## which unpaused the game and left this menu stuck on screen.
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(Color(1, 0.55, 0.15), Color(0.04, 0.03, 0.07, 0.96)))
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(1500, 880)
	panel.offset_left = -750.0
	panel.offset_top = -440.0
	panel.offset_right = 750.0
	panel.offset_bottom = 440.0
	var column := UiKit.vbox(panel, 10)
	column.mouse_filter = Control.MOUSE_FILTER_PASS

	var header := UiKit.hbox(column)
	var title := UiKit.label(header, 34, Color(1, 0.6, 0.2), 8)
	title.text = "WEAPON TEST MENU"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hint := UiKit.label(header, 20, Color(0.7, 0.7, 0.75))
	hint.text = "F4 / Esc to close   •   Equip = straight into your hands   •   Spawn = on the floor in front of you"

	var body := UiKit.hbox(column, 24)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_PASS

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 2.2
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for weapon in WeaponLibrary.ALL:
		_add_weapon_row(grid, weapon)

	var tools := UiKit.vbox(body, 8)
	tools.mouse_filter = Control.MOUSE_FILTER_PASS
	tools.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tools_title := UiKit.label(tools, 24, Color(1, 0.85, 0.4), 6)
	tools_title.text = "TEST TOOLS"
	_tool(tools, "Spawn ALL weapons around me", _spawn_all)
	_tool(tools, "Spawn training dummy", spawn_enemy.bind(DUMMY))
	_tool(tools, "Spawn chicken", spawn_enemy.bind(CHICKEN))
	_tool(tools, "Spawn First Descendant (boss)", spawn_enemy.bind(FIRST_DESCENDANT, 12.0))
	_tool(tools, "Refill all ammo", func() -> void: _player().arsenal.refill_ammo(1.0))
	_tool(tools, "Give / charge Infinite Pistol", charge_pistol)
	_tool(tools, "Drop an Infinite Pistol jackpot", _jackpot)
	_tool(tools, "Spawn ammo, cash and health", _spawn_supplies)
	_tool(tools, "Kill all enemies", _kill_all)
	_tool(tools, "Clear weapons off the floor", _clear_floor)
	_tool(tools, "Empty my hands", func() -> void: _player().arsenal.clear())
	_health_button = _tool(tools, "", _toggle_infinite_health)
	_tool(tools, "Close", close)


func _add_weapon_row(grid: GridContainer, weapon: WeaponData) -> void:
	var color := Rarity.color(weapon.rarity)
	var name_label := UiKit.label(grid, 22, color, 6)
	name_label.text = weapon.display_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rarity := UiKit.label(grid, 18, color)
	rarity.text = "%s (rank %s)" % [Rarity.display_name(weapon.rarity), Rarity.rank_text(weapon.rarity)]
	var tags := UiKit.label(grid, 16, Color(0.75, 0.75, 0.8))
	tags.text = weapon.weapon_type + ("  •  " + ", ".join(UiKit.weapon_tags(weapon)) if not UiKit.weapon_tags(weapon).is_empty() else "")
	tags.custom_minimum_size.x = 330.0
	tags.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(grid, "Equip", _equip.bind(weapon))
	_button(grid, "Spawn", spawn_weapon.bind(weapon))


func _tool(parent: Node, text: String, callback: Callable) -> Button:
	var button := _button(parent, text, callback)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 20)
	button.custom_minimum_size = Vector2(90, 40)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


## A point on the floor a few metres in front of the player, toward their aim.
func _in_front(distance := 3.0) -> Vector3:
	var player := _player()
	var forward := player.aim_point - player.global_position
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.1 else Vector3.FORWARD
	return Loot.landing_spot(player, player.global_position, distance, distance, atan2(forward.z, forward.x))


func _equip(weapon: WeaponData) -> void:
	var arsenal := _player().arsenal
	if weapon == WeaponLibrary.INFINITE_PISTOL:
		arsenal.give_infinite_pistol(true)
	else:
		arsenal.add_weapon(WeaponSlot.new(weapon))


func spawn_weapon(weapon: WeaponData) -> void:
	var player := _player()
	Loot.spawn_weapon(player, WeaponSlot.new(weapon), player.global_position + Vector3.UP, _in_front())


func _spawn_all() -> void:
	var player := _player()
	var weapons := WeaponLibrary.ALL
	for i in weapons.size():
		var angle := TAU * i / weapons.size()
		Loot.spawn_weapon(player, WeaponSlot.new(weapons[i]), player.global_position + Vector3.UP,
			Loot.landing_spot(player, player.global_position, 4.0, 4.0, angle))


func spawn_enemy(scene: PackedScene, drop_height := 0.0) -> void:
	var enemy := scene.instantiate() as Node3D
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = _in_front(5.0) + Vector3.UP * (drop_height + 0.1)


func charge_pistol() -> void:
	var arsenal := _player().arsenal
	if arsenal.pistol == null:
		arsenal.give_infinite_pistol(true)
	else:
		arsenal.charge_pistol()


func _jackpot() -> void:
	# A stand-in "enemy" at the cursor so the real jackpot code runs.
	var stand_in := Enemy.new()
	var health := Health.new()
	health.name = "Health"
	stand_in.add_child(health)
	get_tree().current_scene.add_child(stand_in)
	stand_in.global_position = _in_front(4.0)
	Loot.jackpot(stand_in)
	stand_in.queue_free()


func _spawn_supplies() -> void:
	var player := _player()
	for kind in [LootPickup.Kind.AMMO, LootPickup.Kind.MONEY, LootPickup.Kind.HEALTH]:
		Loot.spawn_item(player, kind, 20, player.global_position + Vector3.UP, _in_front(2.5 + kind))


func _kill_all() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		(enemy as Enemy).health.take_damage(99999)


func _clear_floor() -> void:
	for node in get_tree().current_scene.find_children("*", "WeaponPickup", true, false):
		node.queue_free()


func _toggle_infinite_health() -> void:
	var health := _player().health
	health.infinite_health = not health.infinite_health
	_refresh_health_label()


func _refresh_health_label() -> void:
	var player := _player()
	if _health_button and player:
		_health_button.text = "Infinite Health: %s" % ("ON" if player.health.infinite_health else "OFF")

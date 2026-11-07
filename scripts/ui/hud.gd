extends CanvasLayer
## Gameplay HUD: the health/dash bar (the team's sprite: three red health segments and a green dash block that
## refills like water, see shaders/), currencies, current objective and short pop-up messages,
## plus the weapon panel, the item card for weapons on the floor, a boss health bar and a red flash when hurt.
## Top right: the Infinite Pistol's charge coins (PistolCharge).
## The weapon card, panel, pistol coins and boss bar are built in code (see WeaponCard, WeaponPanel, PistolCharge).
## The style meter gets added here later.

## Gap between a pickup's position on screen and its item card.
const CARD_OFFSET := Vector2(70, -40)
const SCREEN_MARGIN := 16.0

@export var player: Player

@onready var _root: Control = $Root
@onready var _health_segments: Array[TextureRect] = [%HealthSegment1, %HealthSegment2, %HealthSegment3]
@onready var _dash_fill: TextureRect = %DashFill
@onready var _currency_label: Label = %CurrencyLabel
@onready var _objective_label: Label = %ObjectiveLabel
@onready var _message_label: Label = %MessageLabel

var _message_tween: Tween
var _weapon_panel: WeaponPanel
var _pistol_charge: PistolCharge
var _card: WeaponCard
var _card_target: WeaponPickup
var _boss: Enemy
var _boss_box: VBoxContainer
var _boss_name: Label
var _boss_bar: ProgressBar
var _hurt_flash: ColorRect
var _health := 0
var _max_health := 1
## Health shown pale in the segments: lags behind real health after a hit, then drains down to it.
var _ghost_health := 0.0
var _ghost_tween: Tween
var _dash_level := 1.0


func _ready() -> void:
	add_to_group("hud")
	_message_label.modulate.a = 0.0
	_build_weapon_ui()
	_build_boss_bar()
	_build_hurt_flash()
	GameState.currency_changed.connect(_on_currency_changed)
	_on_currency_changed(GameState.weapon_currency, GameState.relic_currency)

	if player == null:
		push_warning("HUD has no player assigned.")
		return
	if not player.is_node_ready():
		await player.ready
	player.health.changed.connect(_on_health_changed)
	player.health.damaged.connect(_on_player_damaged)
	_on_health_changed(player.health.current, player.health.max_health)
	player.arsenal.changed.connect(_refresh_weapons)
	player.arsenal.focus_changed.connect(_on_focus_changed)
	_pistol_charge.watch(player.arsenal)
	_refresh_weapons()


func _process(_delta: float) -> void:
	if player:
		_set_dash_level(player.dash_recharge_progress())
	_place_card()
	if _boss_box.visible and not is_instance_valid(_boss):
		_boss_box.visible = false


func set_objective(text: String) -> void:
	_objective_label.text = text


## Shows text in the middle of the screen for a moment, then fades it out.
func show_message(text: String, duration := 2.5) -> void:
	_message_label.text = text
	if _message_tween:
		_message_tween.kill()
	_message_label.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(duration)
	_message_tween.tween_property(_message_label, "modulate:a", 0.0, 0.5)


## Shows a health bar for this enemy at the top of the screen until it dies.
func track_boss(enemy: Enemy) -> void:
	_boss = enemy
	_boss_name.text = enemy.display_name
	_boss_bar.max_value = enemy.health.max_health
	_boss_bar.value = enemy.health.current
	_boss_box.visible = true
	enemy.health.changed.connect(func(current: int, _maximum: int) -> void: _boss_bar.value = current)
	enemy.killed.connect(func(_enemy: Enemy) -> void: _boss_box.visible = false)


func _refresh_weapons() -> void:
	_weapon_panel.refresh(player.arsenal)
	_pistol_charge.refresh(player.arsenal)
	if is_instance_valid(_card_target):
		_on_focus_changed(_card_target)


func _on_focus_changed(pickup: WeaponPickup) -> void:
	_card_target = pickup
	if pickup == null or pickup.slot == null:
		_card.visible = false
		return
	_card.show_weapon(pickup.slot, player.arsenal.current(), player.arsenal.slot_to_replace())
	_place_card()


## Keeps the item card beside its pickup on screen, inside the screen edges.
func _place_card() -> void:
	if not _card.visible:
		return
	if not is_instance_valid(_card_target) or _card_target.slot == null:
		_card.visible = false
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var screen := camera.unproject_position(_card_target.global_position + Vector3.UP)
	var view := _root.size
	var position := screen + CARD_OFFSET
	if position.x + _card.size.x > view.x - SCREEN_MARGIN:
		position.x = screen.x - CARD_OFFSET.x - _card.size.x
	position.x = clampf(position.x, SCREEN_MARGIN, view.x - _card.size.x - SCREEN_MARGIN)
	position.y = clampf(position.y - _card.size.y * 0.5, SCREEN_MARGIN, view.y - _card.size.y - SCREEN_MARGIN)
	_card.position = position


func _on_health_changed(current: int, maximum: int) -> void:
	_health = current
	_max_health = maxi(maximum, 1)
	if _ghost_tween:
		_ghost_tween.kill()
	if current >= _ghost_health:
		_ghost_health = current
	else:
		_ghost_tween = create_tween()
		_ghost_tween.tween_interval(0.35)
		_ghost_tween.tween_method(_set_ghost_health, _ghost_health, float(current), 0.3)
	_update_health_segments()


func _set_ghost_health(value: float) -> void:
	_ghost_health = value
	_update_health_segments()


## Each segment holds a third of max health and drains from its right edge, the last segment first.
func _update_health_segments() -> void:
	var per_segment := float(_max_health) / _health_segments.size()
	for i in _health_segments.size():
		var material := _health_segments[i].material as ShaderMaterial
		material.set_shader_parameter("fill", clampf((_health - i * per_segment) / per_segment, 0.0, 1.0))
		material.set_shader_parameter("ghost", clampf((_ghost_health - i * per_segment) / per_segment, 0.0, 1.0))


## The dash block fills like water while recharging and flashes when the dash is ready again.
func _set_dash_level(level: float) -> void:
	if is_equal_approx(level, _dash_level):
		return
	if level >= 1.0 and _dash_level < 1.0:
		_dash_fill.modulate = Color(2.2, 2.2, 2.2)
		create_tween().tween_property(_dash_fill, "modulate", Color.WHITE, 0.3)
	_dash_level = level
	(_dash_fill.material as ShaderMaterial).set_shader_parameter("level", level)


func _on_player_damaged(_amount: int, _kind: Health.Kind) -> void:
	_hurt_flash.color.a = 0.35
	create_tween().tween_property(_hurt_flash, "color:a", 0.0, 0.35)


func _on_currency_changed(weapon: int, relic: int) -> void:
	_currency_label.text = "Weapon $%d     Relic %d" % [weapon, relic]


func _build_weapon_ui() -> void:
	_weapon_panel = WeaponPanel.new()
	_root.add_child(_weapon_panel)
	_weapon_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 32)
	_weapon_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_weapon_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_card = WeaponCard.new()
	_root.add_child(_card)
	_pistol_charge = PistolCharge.new()
	_root.add_child(_pistol_charge)
	# Pinned 32 px from the top right corner; grows to the left as wide as its coins.
	_pistol_charge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 32)
	_pistol_charge.grow_horizontal = Control.GROW_DIRECTION_BEGIN


func _build_boss_bar() -> void:
	_boss_box = UiKit.vbox(_root, 4)
	_boss_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_box.offset_left = -480.0
	_boss_box.offset_right = 480.0
	_boss_box.offset_top = 90.0
	_boss_name = UiKit.label(_boss_box, 30, Color(1, 0.45, 0.3), 8)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size = Vector2(960, 24)
	_boss_bar.show_percentage = false
	_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.08, 0.04, 0.06, 0.85)
	background.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.9, 0.25, 0.15)
	fill.set_corner_radius_all(4)
	_boss_bar.add_theme_stylebox_override("background", background)
	_boss_bar.add_theme_stylebox_override("fill", fill)
	_boss_box.add_child(_boss_bar)
	_boss_box.visible = false


func _build_hurt_flash() -> void:
	_hurt_flash = ColorRect.new()
	_hurt_flash.color = Color(0.9, 0.05, 0.05, 0.0)
	_hurt_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hurt_flash)
	_hurt_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.move_child(_hurt_flash, 0)

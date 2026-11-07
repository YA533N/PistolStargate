class_name WeaponCard
extends PanelContainer
## Borderlands-style item card for the weapon on the floor the player is about to pick up: the gun's
## silhouette, name, rarity and rank, damage, stats compared with the equipped gun (green/red arrows),
## what it does and its flavour text. The HUD places it next to the focused WeaponPickup.

const WIDTH := 470.0
const PREVIEW_SIZE := Vector2i(434, 150)
const BETTER := Color(0.35, 1, 0.4)
const WORSE := Color(1, 0.35, 0.3)

var _style: StyleBoxFlat
var _name: Label
var _type: Label
var _rarity: Label
var _rank: Label
var _rank_style: StyleBoxFlat
var _damage: Label
var _damage_caption: Label
var _stats: GridContainer
var _tags: Label
var _description: Label
var _flavor: Label
var _footer: Label
var _viewport: SubViewport
var _camera: Camera3D
var _pivot: Node3D
var _silhouette_material := StandardMaterial3D.new()
var _time := 0.0


func _ready() -> void:
	custom_minimum_size.x = WIDTH
	mouse_filter = MOUSE_FILTER_IGNORE
	_style = UiKit.panel_style(Color.WHITE)
	add_theme_stylebox_override("panel", _style)
	var column := UiKit.vbox(self, 6)

	_name = UiKit.label(column, 32, Color.WHITE, 8)
	var type_row := UiKit.hbox(column)
	_type = UiKit.label(type_row, 20, Color(0.75, 0.75, 0.8))
	_type.size_flags_horizontal = SIZE_EXPAND_FILL
	_rarity = UiKit.label(type_row, 22, Color.WHITE, 6)
	_rank = UiKit.label(type_row, 20, Color(0.05, 0.05, 0.08))
	_rank_style = StyleBoxFlat.new()
	_rank_style.set_corner_radius_all(4)
	_rank_style.content_margin_left = 8.0
	_rank_style.content_margin_right = 8.0
	_rank.add_theme_stylebox_override("normal", _rank_style)

	_build_preview(column)

	var damage_row := UiKit.hbox(column, 14)
	_damage = UiKit.label(damage_row, 52, Color.WHITE, 8)
	_damage_caption = UiKit.label(damage_row, 18, Color(0.75, 0.75, 0.8))
	_damage_caption.size_flags_vertical = SIZE_SHRINK_CENTER
	_stats = GridContainer.new()
	_stats.columns = 3
	_stats.add_theme_constant_override("h_separation", 14)
	_stats.mouse_filter = MOUSE_FILTER_IGNORE
	_stats.size_flags_horizontal = SIZE_EXPAND_FILL
	damage_row.add_child(_stats)

	_tags = UiKit.label(column, 19, Color.WHITE)
	_description = UiKit.label(column, 19, Color(0.92, 0.92, 0.95))
	_flavor = UiKit.label(column, 18, Color(1, 0.4, 0.3))
	# Wrapped labels need a fixed width, or the card measures them one letter wide and grows very tall.
	for wrapped in [_tags, _description, _flavor]:
		wrapped.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		wrapped.custom_minimum_size.x = WIDTH - 36.0
	_footer = UiKit.label(column, 22, Color(1, 0.85, 0.35), 6)
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	visible = false


func _process(delta: float) -> void:
	_time += delta
	if _pivot:
		_pivot.rotation.y = sin(_time * 1.2) * 0.25


## equipped: the gun in the player's hand (for the stat arrows). replaces: the gun picking this up would swap out.
func show_weapon(slot: WeaponSlot, equipped: WeaponSlot, replaces: WeaponSlot) -> void:
	var weapon := slot.data
	var color := Rarity.color(weapon.rarity)
	_style.border_color = color
	_name.text = weapon.display_name
	_name.add_theme_color_override("font_color", color)
	_type.text = "%s   Lv %s" % [weapon.weapon_type, "??" if weapon.level >= 99 else str(weapon.level)]
	_rarity.text = Rarity.display_name(weapon.rarity).to_upper()
	_rarity.add_theme_color_override("font_color", color)
	_rank.text = "RANK %s" % Rarity.rank_text(weapon.rarity)
	_rank_style.bg_color = color

	var compare := equipped.data if equipped and equipped.data != weapon else null
	if weapon.instant_kill_normal:
		_damage.text = "∞"
		_damage_caption.text = "INSTANT KILL\n(normal enemies)"
	else:
		_damage.text = str(weapon.damage) + ("x%d" % weapon.pellets if weapon.pellets > 1 else "")
		_damage_caption.text = "DAMAGE" + _arrow_text(weapon.damage_per_shot(), float(compare.damage_per_shot()) if compare else -1.0)
	_damage.add_theme_color_override("font_color", color.lerp(Color.WHITE, 0.4))

	for child in _stats.get_children():
		child.queue_free()
	var rate := maxf(weapon.fire_rate, weapon.max_fire_rate)
	_add_stat("Fire rate", "%.1f/s" % rate, rate, maxf(compare.fire_rate, compare.max_fire_rate) if compare else -1.0)
	_add_stat("Accuracy", "%d%%" % weapon.accuracy_percent(), weapon.accuracy_percent(), float(compare.accuracy_percent()) if compare else -1.0)
	_add_stat("Ammo", "%d/%d" % [slot.ammo, weapon.max_ammo], slot.ammo, -1.0)

	_tags.text = "  •  ".join(UiKit.weapon_tags(weapon))
	_tags.add_theme_color_override("font_color", color)
	_description.text = weapon.description
	_flavor.text = weapon.flavor_text
	_flavor.visible = not weapon.flavor_text.is_empty()
	_footer.text = "[E] Swap for %s" % replaces.data.display_name if replaces else "[E] Pick up"
	_set_preview(weapon, color)
	visible = true
	size = Vector2.ZERO
	reset_size.call_deferred()


func _add_stat(caption: String, value: String, mine: float, theirs: float) -> void:
	UiKit.label(_stats, 17, Color(0.7, 0.7, 0.75)).text = caption
	UiKit.label(_stats, 19, Color.WHITE).text = value
	var arrow := UiKit.label(_stats, 17, Color.WHITE)
	arrow.text = ""
	if theirs >= 0.0 and not is_equal_approx(mine, theirs):
		arrow.text = "▲" if mine > theirs else "▼"
		arrow.add_theme_color_override("font_color", BETTER if mine > theirs else WORSE)


func _arrow_text(mine: float, theirs: float) -> String:
	if theirs < 0.0 or is_equal_approx(mine, theirs):
		return ""
	return "  ▲" if mine > theirs else "  ▼"


func _build_preview(parent: Node) -> void:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.custom_minimum_size = Vector2(PREVIEW_SIZE)
	container.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(container)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.size = PREVIEW_SIZE
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	container.add_child(_viewport)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_viewport.add_child(_camera)
	# Looking from +X toward the origin, so a barrel pointing along -Z faces screen right.
	_camera.look_at_from_position(Vector3(4, 0, 0), Vector3.ZERO, Vector3.UP)
	_silhouette_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


## Rebuilds the silhouette: the weapon's model in one flat colour, centred and sized to fit.
func _set_preview(weapon: WeaponData, color: Color) -> void:
	if _pivot:
		_pivot.queue_free()
	_pivot = Node3D.new()
	_viewport.add_child(_pivot)
	var model := weapon.build_model()
	_pivot.add_child(model)
	var bounds := WeaponData.mesh_bounds(model)
	model.position = -bounds.get_center()
	_silhouette_material.albedo_color = color.lerp(Color.WHITE, 0.35)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_override = _silhouette_material
	var aspect := float(PREVIEW_SIZE.x) / PREVIEW_SIZE.y
	_camera.size = maxf(bounds.size.z * 1.15 / aspect, bounds.size.y * 1.25)

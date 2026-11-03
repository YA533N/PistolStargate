class_name UiKit
## Small helpers for HUD pieces built in code (weapon card, weapon panel, cheat menu), so they share one look.


static func label(parent: Node, font_size: int, color := Color.WHITE, outline := 0) -> Label:
	var result := Label.new()
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	if outline > 0:
		result.add_theme_constant_override("outline_size", outline)
		result.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result


static func panel_style(border: Color, background := Color(0.03, 0.03, 0.06, 0.92), border_width := 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	return style


static func vbox(parent: Node, separation := 6) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	return box


static func hbox(parent: Node, separation := 10) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	return box


## Short tags for what makes a weapon special, e.g. ["Pierce 3", "Explodes 2.4 m"].
static func weapon_tags(weapon: WeaponData) -> PackedStringArray:
	var tags := PackedStringArray()
	if weapon.instant_kill_normal:
		tags.append("Instant kill")
	if weapon.automatic:
		tags.append("Automatic")
	if weapon.pellets > 1:
		tags.append("%d pellets" % weapon.pellets)
	if weapon.hitscan:
		tags.append("Beam")
	if weapon.pierce < 0:
		tags.append("Pierces all")
	elif weapon.pierce > 0:
		tags.append("Pierce %d" % weapon.pierce)
	if weapon.bounces > 0:
		tags.append("Ricochet x%d" % weapon.bounces)
	if weapon.explosion_radius > 0.0:
		tags.append("Explodes %.1f m" % weapon.explosion_radius)
	if weapon.poison_dps > 0:
		tags.append("Poison %d/s" % weapon.poison_dps)
	if weapon.chain_count > 0:
		tags.append("Chain x%d" % weapon.chain_count)
	if weapon.homing_turn_rate > 0.0:
		tags.append("Homing")
	if weapon.max_fire_rate > weapon.fire_rate:
		tags.append("Spin-up")
	return tags

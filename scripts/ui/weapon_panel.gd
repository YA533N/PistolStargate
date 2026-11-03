class_name WeaponPanel
extends PanelContainer
## Bottom-right HUD block: the weapon in hand (name in rarity colour, big ammo count), the other slots,
## and the Infinite Pistol's charge (kills toward the next shot).

var _style: StyleBoxFlat
var _name: Label
var _ammo: Label
var _ammo_max: Label
var _pistol: Label
var _slots: VBoxContainer
var _hint: Label


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size.x = 400.0
	_style = UiKit.panel_style(Color(0.4, 0.4, 0.45), Color(0.03, 0.03, 0.06, 0.8), 2)
	add_theme_stylebox_override("panel", _style)
	var column := UiKit.vbox(self, 4)
	_name = UiKit.label(column, 28, Color.WHITE, 6)
	var ammo_row := UiKit.hbox(column, 6)
	_ammo = UiKit.label(ammo_row, 54, Color.WHITE, 8)
	_ammo_max = UiKit.label(ammo_row, 24, Color(0.7, 0.7, 0.75))
	_ammo_max.size_flags_vertical = SIZE_SHRINK_END
	_pistol = UiKit.label(column, 22, Rarity.color(Rarity.Tier.INFINITE), 6)
	_slots = UiKit.vbox(column, 2)
	_hint = UiKit.label(column, 16, Color(0.6, 0.6, 0.66))
	_hint.text = "[Q]/wheel swap   [1][2][3] select   [F] pick up"


func refresh(arsenal: Arsenal) -> void:
	var current := arsenal.current()
	if current == null:
		_name.text = "UNARMED"
		_name.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		_ammo.text = "--"
		_ammo_max.text = ""
		_style.border_color = Color(0.4, 0.4, 0.45)
	else:
		var color := Rarity.color(current.data.rarity)
		_name.text = current.data.display_name
		_name.add_theme_color_override("font_color", color)
		_style.border_color = color
		if current == arsenal.pistol:
			_ammo.text = "READY" if not current.is_out_of_ammo() else "EMPTY"
			_ammo_max.text = ""
		else:
			_ammo.text = "EMPTY" if current.is_out_of_ammo() else str(current.ammo)
			_ammo_max.text = "/ %d" % current.data.max_ammo
		_ammo.add_theme_color_override("font_color", Color(1, 0.35, 0.3) if current.is_out_of_ammo() else Color.WHITE)

	_pistol.visible = arsenal.pistol != null
	if arsenal.pistol:
		if arsenal.pistol.is_out_of_ammo():
			var needed := arsenal.pistol.data.kills_per_charge
			_pistol.text = "∞ PISTOL  charging  %s%s" % ["●".repeat(arsenal.pistol_kills), "○".repeat(needed - arsenal.pistol_kills)]
		else:
			_pistol.text = "∞ PISTOL  READY"

	for child in _slots.get_children():
		child.queue_free()
	var loadout := arsenal.loadout()
	for i in loadout.size():
		var slot := loadout[i]
		var line := UiKit.label(_slots, 19, Rarity.color(slot.data.rarity))
		var ammo_text := ("ready" if not slot.is_out_of_ammo() else "empty") if slot == arsenal.pistol else str(slot.ammo)
		line.text = "%s[%d] %s   %s" % ["> " if i == arsenal.active else "   ", i + 1, slot.data.display_name, ammo_text]
		if i != arsenal.active:
			line.modulate.a = 0.65

class_name Arsenal
extends Node
## The player's weapons: SLOT_COUNT slots for guns found on the floor, plus the Infinite Pistol once the
## Orange Trooper hands it over. Handles shooting, ammo, swapping, picking up and dropping weapons, and
## charging the Infinite Pistol with kills.
## Saved to GameState.loadout on every change, so it survives scene changes and reloads.
## Expects to be a child of the Player.

## Slots, ammo, the active weapon or the pistol's charge changed.
signal changed
## The weapon on the floor that E would pick up changed. Null when there is none.
signal focus_changed(pickup: WeaponPickup)
## The Infinite Pistol just filled up from kills (or the cheat). The HUD plays its slot machine.
signal pistol_charged

const SLOT_COUNT := 2
## Seconds between repeated "out of ammo" messages.
const WARNING_COOLDOWN := 1.5

## The gun model is parented here (it turns with the player's aim).
@export var hand: Node3D

var slots: Array[WeaponSlot] = []
## The Infinite Pistol, or null before the Orange Trooper hands it over.
var pistol: WeaponSlot
## Kills since the pistol's last charge.
var pistol_kills := 0
## Index into loadout(): the slots first, then the pistol.
var active := 0
## The nearest weapon on the floor in reach, or null.
var focused_pickup: WeaponPickup
## The gun currently in the hand, or null.
var held: Weapon

var _nearby: Array[WeaponPickup] = []
var _shot_queued := false
var _warning_cooldown := 0.0

@onready var _player := get_parent() as Player


func _ready() -> void:
	GameState.enemy_killed.connect(_on_enemy_killed)
	changed.connect(_save)
	_load(GameState.loadout)
	_equip_active()


## Everything the player can switch between, in order: slot 1, slot 2, then the Infinite Pistol.
func loadout() -> Array[WeaponSlot]:
	var list: Array[WeaponSlot] = slots.duplicate()
	if pistol:
		list.append(pistol)
	return list


func current() -> WeaponSlot:
	var list := loadout()
	return list[active] if active >= 0 and active < list.size() else null


## Called by the Player every physics frame.
func update(aim_point: Vector3, input_enabled: bool, delta: float) -> void:
	_warning_cooldown = maxf(_warning_cooldown - delta, 0.0)
	_update_focus()
	var slot := current()
	var holding := input_enabled and Input.is_action_pressed("shoot")
	if held:
		held.trigger_held = holding and slot != null and not slot.is_out_of_ammo()
	# Semi-automatic guns fire once per click (queued from the input event so fast clicks aren't lost);
	# automatic guns fire for as long as the button is held.
	var wants_shot := _shot_queued or (holding and slot != null and slot.data.automatic)
	_shot_queued = false
	if not input_enabled or not wants_shot:
		return
	if slot == null:
		_warn("No weapon! Find one first.")
		return
	if slot.is_out_of_ammo():
		_warn_empty(slot)
		return
	var on_miss := _refund_pistol if slot == pistol and slot.data.refund_on_miss else Callable()
	if held.fire(aim_point, on_miss):
		slot.ammo -= slot.data.ammo_per_shot
		changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if _player == null or not _player.input_enabled:
		return
	if event.is_action_pressed("shoot"):
		_shot_queued = true
	elif event.is_action_pressed("interact") and focused_pickup:
		get_viewport().set_input_as_handled()
		pick_up(focused_pickup)
	elif event.is_action_pressed("swap_weapon"):
		var mouse := event as InputEventMouseButton
		cycle(-1 if mouse and mouse.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
	elif event.is_action_pressed("weapon_1"):
		select(0)
	elif event.is_action_pressed("weapon_2"):
		select(1)
	elif event.is_action_pressed("weapon_3"):
		select(2)


func select(index: int) -> void:
	if index == active or index < 0 or index >= loadout().size():
		return
	active = index
	_equip_active()
	changed.emit()


func cycle(step: int) -> void:
	var count := loadout().size()
	if count < 2:
		return
	active = posmod(active + step, count)
	_equip_active()
	changed.emit()


func pick_up(pickup: WeaponPickup) -> void:
	if not is_instance_valid(pickup) or not pickup.can_be_picked():
		return
	var slot := pickup.take()
	add_weapon(slot)
	_message("Picked up %s" % slot.data.display_name, 1.2)


## Puts a weapon in a slot and equips it: a free slot first, then one that's out of ammo, then the
## active one. The weapon it replaces is dropped on the floor (or thrown away if it was empty).
func add_weapon(slot: WeaponSlot) -> void:
	var index := _slot_for_new_weapon()
	if index < slots.size():
		_drop(slots[index])
		slots[index] = slot
	else:
		slots.append(slot)
		index = slots.size() - 1
	active = index
	_equip_active()
	changed.emit()


func give_infinite_pistol(charged := true) -> void:
	pistol = WeaponSlot.new(WeaponLibrary.INFINITE_PISTOL, 1 if charged else 0)
	pistol_kills = 0
	active = loadout().size() - 1
	_equip_active()
	changed.emit()


func charge_pistol() -> void:
	if pistol:
		pistol.ammo = pistol.data.max_ammo
		pistol_kills = 0
		pistol_charged.emit()
		changed.emit()


## Adds fraction of each slot weapon's max ammo (not the pistol's). Returns false if all were full.
func refill_ammo(fraction: float) -> bool:
	var refilled := false
	for slot in slots:
		refilled = slot.refill(fraction) or refilled
	if refilled:
		changed.emit()
	return refilled


func clear() -> void:
	slots.clear()
	pistol = null
	pistol_kills = 0
	active = 0
	_equip_active()
	changed.emit()


## The weapon a pickup would swap out right now, or null if there's a free slot.
func slot_to_replace() -> WeaponSlot:
	var index := _slot_for_new_weapon()
	return slots[index] if index < slots.size() else null


## Kills still needed for the next pistol shot (0 when it's loaded).
func pistol_kills_needed() -> int:
	if pistol == null or not pistol.is_out_of_ammo():
		return 0
	return pistol.data.kills_per_charge - pistol_kills


func add_nearby(pickup: WeaponPickup) -> void:
	if not pickup in _nearby:
		_nearby.append(pickup)


func remove_nearby(pickup: WeaponPickup) -> void:
	_nearby.erase(pickup)


func _update_focus() -> void:
	var best: WeaponPickup = null
	var best_distance := INF
	for pickup in _nearby.duplicate():
		if not is_instance_valid(pickup):
			_nearby.erase(pickup)
			continue
		if not pickup.can_be_picked():
			continue
		var distance: float = pickup.global_position.distance_squared_to(_player.global_position)
		if distance < best_distance:
			best_distance = distance
			best = pickup
	if best == focused_pickup:
		return
	if is_instance_valid(focused_pickup):
		focused_pickup.set_focused(false)
	focused_pickup = best
	if best:
		best.set_focused(true)
	focus_changed.emit(best)


func _slot_for_new_weapon() -> int:
	if slots.size() < SLOT_COUNT:
		return slots.size()
	for i in slots.size():
		if slots[i].is_out_of_ammo():
			return i
	return active if active < slots.size() else 0


func _drop(slot: WeaponSlot) -> void:
	var origin := _player.global_position
	if slot.is_out_of_ammo():
		Effects.float_text(_player, origin + Vector3.UP * 2.2, "Tossed the empty %s" % slot.data.display_name, Color(0.8, 0.8, 0.8), 0.6)
		return
	Loot.spawn_weapon(_player, slot, origin + Vector3.UP, Loot.landing_spot(_player, origin, 1.6, 2.2))


func _equip_active() -> void:
	if held:
		held.queue_free()
		held = null
	var slot := current()
	if slot == null or hand == null:
		return
	held = Weapon.new()
	hand.add_child(held)
	held.setup(slot.data)


func _on_enemy_killed(enemy: Node) -> void:
	if pistol == null or pistol.is_full():
		return
	# Kills made by the pistol itself don't recharge it.
	if enemy is Enemy and (enemy as Enemy).killed_by_infinite_pistol:
		return
	pistol_kills += 1
	if pistol_kills >= pistol.data.kills_per_charge:
		pistol_kills = 0
		pistol.ammo = pistol.data.max_ammo
		_message("INFINITE PISTOL CHARGED!  [%s]" % _pistol_key(), 2.0)
		pistol_charged.emit()
	changed.emit()


func _refund_pistol() -> void:
	if pistol == null or pistol.is_full():
		return
	pistol.ammo += 1
	changed.emit()
	Effects.float_text(_player, _player.global_position + Vector3.UP * 2.2, "Missed! The bullet returns to the chamber.", Color(0.6, 1, 1), 0.6)


func _warn_empty(slot: WeaponSlot) -> void:
	if slot == pistol:
		_warn("Infinite Pistol is empty: %d more kill(s) with other guns to recharge." % pistol_kills_needed())
	else:
		_warn("%s is out of ammo! Grab another weapon [E] or swap [Q]." % slot.data.display_name)


func _warn(text: String) -> void:
	if _warning_cooldown > 0.0:
		return
	_warning_cooldown = WARNING_COOLDOWN
	_message(text, 1.5)


func _message(text: String, duration: float) -> void:
	get_tree().call_group("hud", "show_message", text, duration)


func _pistol_key() -> String:
	return str(loadout().find(pistol) + 1)


func _save() -> void:
	var saved_slots := []
	for slot in slots:
		saved_slots.append(slot.to_dict())
	GameState.loadout = {
		"slots": saved_slots,
		"pistol": pistol.ammo if pistol else -1,
		"pistol_kills": pistol_kills,
		"active": active,
	}


func _load(saved: Dictionary) -> void:
	slots.clear()
	for entry in saved.get("slots", []):
		var slot := WeaponSlot.from_dict(entry)
		if slot and slots.size() < SLOT_COUNT:
			slots.append(slot)
	var pistol_ammo: int = saved.get("pistol", -1)
	pistol = WeaponSlot.new(WeaponLibrary.INFINITE_PISTOL, pistol_ammo) if pistol_ammo >= 0 else null
	pistol_kills = saved.get("pistol_kills", 0)
	active = clampi(saved.get("active", 0), 0, maxi(loadout().size() - 1, 0))

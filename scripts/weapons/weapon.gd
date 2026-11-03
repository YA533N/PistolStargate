class_name Weapon
extends Node3D
## A gun in someone's hand, built from a WeaponData with setup(). fire() shoots toward a point.
## Ammo is not tracked here: the player's Arsenal (or an enemy) decides whether a shot is allowed.

signal fired

## Closer than this, the target is beside or behind the muzzle, so fire straight ahead instead.
const MIN_AIM_DISTANCE := 1.5

var data: WeaponData
## Set every physics frame by whoever holds the gun. Drives spin-up weapons.
var trigger_held := false
var collision_mask := Combat.PLAYER_SHOT_MASK

var _model: Node3D
var _muzzle_local := Vector3.ZERO
var _cooldown := 0.0
var _spin := 0.0
var _kick := 0.0


func setup(weapon: WeaponData) -> void:
	data = weapon
	_model = weapon.build_model()
	add_child(_model)
	_muzzle_local = weapon.muzzle_in(_model)


func muzzle_position() -> Vector3:
	return global_transform * _muzzle_local


func current_fire_rate() -> float:
	if data.max_fire_rate <= data.fire_rate:
		return data.fire_rate
	return lerpf(data.fire_rate, data.max_fire_rate, _spin)


## 0 to 1, how far a spin-up weapon has wound up.
func spin() -> float:
	return _spin


func _physics_process(delta: float) -> void:
	if data == null:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if data.spin_up_time > 0.0:
		var direction := 1.0 if trigger_held else -2.0
		_spin = clampf(_spin + direction * delta / data.spin_up_time, 0.0, 1.0)
	# Recoil: the model jumps back a little on each shot and slides forward again.
	_kick = move_toward(_kick, 0.0, delta * 1.2)
	_model.position.z = _kick


func can_fire() -> bool:
	return data != null and _cooldown <= 0.0


## Shoots toward target (flattened to the muzzle's height). Returns false while on cooldown.
## on_miss runs if the shot hits no enemy (the Infinite Pistol refunds its bullet).
func fire(target: Vector3, on_miss := Callable()) -> bool:
	if not can_fire():
		return false
	var origin := muzzle_position()
	var direction := target - origin
	direction.y = 0.0
	if direction.length() < MIN_AIM_DISTANCE:
		direction = -global_basis.z
		direction.y = 0.0
	direction = direction.normalized()

	if data.hitscan:
		if not Projectile.fire_beam(self, data, origin, direction, collision_mask) and on_miss.is_valid():
			on_miss.call()
	else:
		for i in data.pellets:
			var projectile := Projectile.new()
			get_tree().current_scene.add_child(projectile)
			var miss_callback := on_miss if i == 0 else Callable()
			projectile.launch(data, origin, direction.rotated(Vector3.UP, _spread_angle(i)), collision_mask, miss_callback)

	_cooldown = 1.0 / current_fire_rate()
	_kick = 0.06 + 0.02 * data.pellets
	Effects.flash(self, origin, data.projectile_color, 0.22, 0.07)
	fired.emit()
	return true


func _spread_angle(pellet: int) -> float:
	var spread := deg_to_rad(data.spread_degrees)
	if data.pellets <= 1:
		return randf_range(-0.5, 0.5) * spread
	# Shotguns: pellets fanned evenly across the cone, with a little jitter.
	return lerpf(-0.5 * spread, 0.5 * spread, float(pellet) / (data.pellets - 1)) + randf_range(-0.03, 0.03)

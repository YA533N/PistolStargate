class_name Projectile
extends Node3D
## One bullet, orb or shard. Each physics frame it ray-casts along the step it is about to move, so fast
## bullets can't skip through thin walls (and it works the same with Jolt or Godot physics).
## Its behaviour - damage, pierce, ricochet, explosion, poison, chain lightning, homing - comes from a WeaponData.
## Made in code by Weapon.fire(); no scene needed.

## How far homing projectiles look for a target.
const HOMING_RANGE := 14.0

var weapon: WeaponData
var collision_mask := Combat.PLAYER_SHOT_MASK
## Height the projectile dips to after leaving the muzzle (at 45 degrees), then holds. NAN keeps the muzzle's
## height. Lets a gun held at chest height fire bullets low enough for low walls to block.
var cruise_height := NAN

var _velocity := Vector3.ZERO
var _age := 0.0
var _pierce_left := 0
var _bounces_left := 0
var _hit_an_enemy := false
var _exclude: Array[RID] = []
var _on_miss := Callable()


## Call right after adding the projectile to the scene. on_miss runs if it ends without hitting anyone.
func launch(data: WeaponData, origin: Vector3, direction: Vector3, mask: int, on_miss := Callable()) -> void:
	weapon = data
	collision_mask = mask
	_on_miss = on_miss
	_pierce_left = data.pierce
	_bounces_left = data.bounces
	global_position = origin
	# Keeps any downward angle (the player shooting from the grapple); enemies pass flat directions.
	_velocity = direction.normalized() * data.projectile_speed
	_build_mesh()
	_face_velocity()


## Instant beam (railgun): damages every enemy on the line up to the first wall.
## Returns true if it hit at least one enemy.
static func fire_beam(context: Node3D, data: WeaponData, origin: Vector3, direction: Vector3, mask: int) -> bool:
	var space := context.get_world_3d().direct_space_state
	var end := origin + direction * data.projectile_range
	var exclude: Array[RID] = []
	var hit_enemy := false
	var pierce_left := data.pierce
	for i in 32:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, end, mask, exclude))
		if hit.is_empty():
			break
		var collider := hit.collider as Node
		if Combat.health_of(collider) == null:
			end = hit.position
			break
		hit_enemy = true
		Combat.hit(collider, data, data.damage)
		Effects.flash(context, hit.position, data.projectile_color, 0.6, 0.15)
		exclude.append(hit.rid)
		if pierce_left == 0:
			end = hit.position
			break
		pierce_left -= 1
	Effects.beam(context, origin, end, data.projectile_color * 1.5, 0.22, 0.35)
	Effects.beam(context, origin, end, Color(1, 1, 1), 0.07, 0.2)
	return hit_enemy


func _physics_process(delta: float) -> void:
	if weapon.homing_turn_rate > 0.0:
		_steer(delta)
	var from := global_position
	var to := from + _velocity * delta
	if not is_nan(cruise_height):
		to.y = move_toward(from.y, cruise_height, weapon.projectile_speed * delta)
	var query := PhysicsRayQueryParameters3D.create(from, to, collision_mask, _exclude)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = to
	elif not _on_hit(hit):
		_finish()
		return
	_age += delta
	if _age >= weapon.lifetime():
		_finish()


## Returns true if the projectile keeps flying (pierce or ricochet).
func _on_hit(hit: Dictionary) -> bool:
	var collider := hit.collider as Node
	var point: Vector3 = hit.position
	var exploding := weapon.explosion_radius > 0.0
	var hurts_enemies := collision_mask & 4 != 0
	if Combat.health_of(collider):
		_hit_an_enemy = true
		Combat.hit(collider, weapon, weapon.damage)
		if exploding:
			Combat.explode(self, point, weapon.explosion_radius, weapon.explosion_damage, weapon.projectile_color, hurts_enemies)
		if weapon.chain_count > 0 and collider is Node3D:
			Combat.chain(self, collider, weapon, weapon.damage)
		Effects.flash(self, point, weapon.projectile_color, 0.4, 0.12)
		if _pierce_left == 0:
			return false
		_pierce_left -= 1
		_exclude.append(hit.rid)
		global_position = point
		return true

	# Hit a wall or prop.
	var normal: Vector3 = hit.normal
	normal.y = 0.0
	if exploding:
		Combat.explode(self, point + normal * 0.2, weapon.explosion_radius, weapon.explosion_damage, weapon.projectile_color, hurts_enemies)
	if _bounces_left > 0 and normal.length_squared() > 0.01:
		_bounces_left -= 1
		normal = normal.normalized()
		_velocity = _velocity.bounce(normal)
		_velocity.y = 0.0
		global_position = point + normal * 0.05
		_face_velocity()
		return true
	if not exploding:
		Effects.flash(self, point, weapon.projectile_color, 0.25, 0.1)
	return false


func _finish() -> void:
	if not _hit_an_enemy and _on_miss.is_valid():
		_on_miss.call()
	queue_free()


func _steer(delta: float) -> void:
	var target := Combat.nearest_enemy(self, global_position, HOMING_RANGE)
	if target == null:
		return
	var desired := target.global_position - global_position
	desired.y = 0.0
	var angle := _velocity.signed_angle_to(desired, Vector3.UP)
	var turn := clampf(angle, -weapon.homing_turn_rate * delta, weapon.homing_turn_rate * delta)
	_velocity = _velocity.rotated(Vector3.UP, turn)
	_face_velocity()


func _face_velocity() -> void:
	if _velocity.length_squared() > 0.001:
		# Straight down from the grapple, UP can't be the up vector.
		var up := Vector3.UP if absf(_velocity.normalized().y) < 0.99 else Vector3.FORWARD
		look_at(global_position + _velocity, up)


func _build_mesh() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = weapon.projectile_size
	sphere.height = weapon.projectile_size * 2.0
	sphere.radial_segments = 10
	sphere.rings = 5
	# Brighter than 1.0 so the environment's glow picks it up.
	sphere.material = Effects.glow_material(weapon.projectile_color * 2.2)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = sphere
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Fast bullets are stretched along their path so they read as tracers.
	mesh_instance.scale = Vector3(1.0, 1.0, clampf(weapon.projectile_speed / 16.0, 1.0, 4.0))
	add_child(mesh_instance)

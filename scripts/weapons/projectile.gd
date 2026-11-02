class_name Projectile
extends Node3D
## A bullet that flies in a straight line. Each physics frame it ray-casts along the step it is about
## to move, so fast bullets can't skip through thin objects (and it works the same with Jolt or Godot
## physics). On a hit it damages the collider's Health child, if there is one, and disappears.

## Seconds before a bullet that hit nothing removes itself.
@export var lifetime := 2.0
## What the bullet can hit. Player bullets: world + enemies.
@export_flags_3d_physics var collision_mask := 5

var _velocity := Vector3.ZERO
var _damage := 0
var _age := 0.0


func launch(origin: Vector3, direction: Vector3, speed: float, damage: int) -> void:
	global_position = origin
	_velocity = direction * speed
	_damage = damage


func _physics_process(delta: float) -> void:
	var from := global_position
	var to := from + _velocity * delta
	var query := PhysicsRayQueryParameters3D.create(from, to, collision_mask)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_on_hit(hit.collider as Node)
		return
	global_position = to
	_age += delta
	if _age >= lifetime:
		queue_free()


func _on_hit(collider: Node) -> void:
	var health := collider.get_node_or_null("Health") as Health if collider else null
	if health:
		health.take_damage(_damage)
	queue_free()

class_name Combat
## Damage rules shared by every gun, the player's and the enemies': the Infinite Pistol's instant kill,
## poison, explosions and chain lightning.

## Player shots hit walls and enemies; enemy shots hit walls and the player (see the layer names in Project Settings).
const PLAYER_SHOT_MASK := 1 | 4
const ENEMY_SHOT_MASK := 1 | 2


## The Health of a body that was hit, or null for walls and props.
static func health_of(node: Node) -> Health:
	if node == null:
		return null
	return node.get_node_or_null("Health") as Health


## One projectile or beam hitting target.
static func hit(target: Node, weapon: WeaponData, amount: int, kind := Health.Kind.NORMAL) -> void:
	var health := health_of(target)
	if health == null or health.is_dead():
		return
	if weapon.instant_kill_normal:
		var enemy := target as Enemy
		if enemy and enemy.tier == Enemy.Tier.NORMAL:
			enemy.killed_by_infinite_pistol = true
			health.take_damage(health.current, Health.Kind.INSTAKILL)
			return
		amount = weapon.elite_damage
	health.take_damage(amount, kind)
	if weapon.poison_dps > 0:
		health.apply_poison(weapon.poison_dps, weapon.poison_duration)


## Damages everything on the other team within radius of center.
static func explode(context: Node, center: Vector3, radius: float, amount: int, color: Color, hurts_enemies := true) -> void:
	Effects.flash(context, center, color, radius, 0.35)
	Effects.shake(context, 0.12)
	var group := "enemies" if hurts_enemies else "player"
	for node in context.get_tree().get_nodes_in_group(group):
		var body := node as Node3D
		if body == null:
			continue
		var offset := body.global_position - center
		offset.y = 0.0
		if offset.length() <= radius + 0.5:
			var health := health_of(body)
			if health:
				health.take_damage(amount, Health.Kind.EXPLOSION)


## Lightning from the enemy that was hit to up to weapon.chain_count others nearby, one after another.
static func chain(context: Node, first: Node3D, weapon: WeaponData, amount: int) -> void:
	var already_hit: Array[Node3D] = [first]
	var from := first
	for i in weapon.chain_count:
		var next := nearest_enemy(context, from.global_position, weapon.chain_range, already_hit)
		if next == null:
			return
		Effects.lightning(context, from.global_position + Vector3.UP, next.global_position + Vector3.UP, weapon.projectile_color)
		var health := health_of(next)
		if health:
			health.take_damage(maxi(1, roundi(amount * weapon.chain_damage_factor)), Health.Kind.CHAIN)
		already_hit.append(next)
		from = next


## Closest living enemy to point on the ground plane, within max_distance. Null if none.
static func nearest_enemy(context: Node, point: Vector3, max_distance: float, exclude: Array[Node3D] = []) -> Node3D:
	var best: Node3D = null
	var best_distance := max_distance
	for node in context.get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node3D
		if enemy == null or enemy in exclude:
			continue
		var offset := enemy.global_position - point
		offset.y = 0.0
		if offset.length() < best_distance:
			best_distance = offset.length()
			best = enemy
	return best

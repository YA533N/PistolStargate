class_name LootPickup
extends Node3D
## Ammo, cash or health on the floor. Collected by walking over it; it flies to the player when they're close.
## Ammo is only taken if a held gun can use it, and health only if the player is hurt.
## With respawn_time > 0 it's a cache that comes back after being taken (arena ammo stations).

enum Kind { AMMO, MONEY, HEALTH }

const MAGNET_RANGE := 3.0
const MAGNET_SPEED := 14.0
const COLLECT_DISTANCE := 0.9
## Share of each gun's maximum ammo that one ammo pickup restores.
const AMMO_FRACTION := 0.35
const COLORS := {Kind.AMMO: Color(1, 0.75, 0.2), Kind.MONEY: Color(0.35, 1, 0.45), Kind.HEALTH: Color(1, 0.25, 0.3)}

@export var kind := Kind.AMMO
## Cash for MONEY, hit points for HEALTH. Unused for AMMO.
@export var amount := 10
## Seconds until a taken pickup comes back. 0 = it's gone for good.
@export var respawn_time := 0.0

var _visual: Node3D
var _label: Label3D
var _landed := true
var _hidden_time := 0.0
var _time := randf() * TAU
var _home := Vector3.ZERO


func _ready() -> void:
	_home = position
	_build_visual()


func _physics_process(delta: float) -> void:
	_time += delta
	if _hidden_time > 0.0:
		_hidden_time -= delta
		if _hidden_time <= 0.0:
			visible = true
			position = _home
		return
	_visual.rotation.y += delta * 2.0
	_visual.position.y = 0.45 + sin(_time * 3.0) * 0.06
	if not _landed:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var target := player.global_position + Vector3.UP * 0.5
	var distance := global_position.distance_to(target)
	if distance > MAGNET_RANGE or not _wanted_by(player):
		return
	if distance < COLLECT_DISTANCE:
		_collect(player)
	elif respawn_time <= 0.0:
		global_position = global_position.move_toward(target, MAGNET_SPEED * delta)


func launch(from: Vector3, to: Vector3, duration := 0.6) -> void:
	_landed = false
	global_position = from
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void: global_position = from.lerp(to, t) + Vector3.UP * 2.0 * 4.0 * t * (1.0 - t), 0.0, 1.0, duration)
	tween.tween_callback(func() -> void: _landed = true)


func _wanted_by(player: Player) -> bool:
	match kind:
		Kind.AMMO:
			for slot in player.arsenal.slots:
				if not slot.is_full():
					return true
			return false
		Kind.HEALTH:
			return player.health.current < player.health.max_health
	return true


func _collect(player: Player) -> void:
	var text := ""
	match kind:
		Kind.AMMO:
			player.arsenal.refill_ammo(AMMO_FRACTION)
			text = "+AMMO"
		Kind.MONEY:
			GameState.add_currency(amount, 0)
			text = "+$%d" % amount
		Kind.HEALTH:
			player.health.heal(amount)
			text = "+%d HP" % amount
	Effects.float_text(self, player.global_position + Vector3.UP * 2.0, text, COLORS[kind], 0.8)
	if respawn_time > 0.0:
		visible = false
		_hidden_time = respawn_time
	else:
		queue_free()


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var color: Color = COLORS[kind]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.5
	material.metallic = 0.6
	material.roughness = 0.3
	match kind:
		Kind.AMMO:
			_add_box(Vector3(0.5, 0.3, 0.32), Vector3.ZERO, material)
			_add_box(Vector3(0.52, 0.08, 0.34), Vector3(0, 0.1, 0), Effects.glow_material(Color(0.15, 0.1, 0.05)))
		Kind.MONEY:
			var coin := CylinderMesh.new()
			coin.top_radius = 0.24
			coin.bottom_radius = 0.24
			coin.height = 0.07
			coin.material = material
			var coin_instance := MeshInstance3D.new()
			coin_instance.mesh = coin
			coin_instance.rotation_degrees.x = 90.0
			_visual.add_child(coin_instance)
		Kind.HEALTH:
			_add_box(Vector3(0.5, 0.16, 0.16), Vector3.ZERO, material)
			_add_box(Vector3(0.16, 0.5, 0.16), Vector3.ZERO, material)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 0.8
	light.omni_range = 1.6
	light.position.y = 0.5
	add_child(light)
	if respawn_time > 0.0:
		_label = Label3D.new()
		_label.text = "AMMO" if kind == Kind.AMMO else ""
		_label.modulate = color
		_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_label.pixel_size = 0.008
		_label.font_size = 40
		_label.outline_size = 12
		_label.position.y = 1.1
		add_child(_label)


func _add_box(size: Vector3, offset: Vector3, material: Material) -> void:
	var box := BoxMesh.new()
	box.size = size
	box.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = box
	instance.position = offset
	_visual.add_child(instance)

class_name WeaponPickup
extends Area3D
## A weapon lying on the floor, spinning above a beam and ring of light in its rarity colour.
## When the player walks into range, their Arsenal focuses the nearest one (the HUD shows its item card)
## and interact (F) picks it up.

## For weapons placed in the editor. Code sets slot instead (that keeps the ammo of a dropped gun).
@export var weapon: WeaponData

var slot: WeaponSlot

@onready var _visual: Node3D = $Visual
@onready var _beam: MeshInstance3D = $Beam
@onready var _ring: MeshInstance3D = $Ring
@onready var _light: OmniLight3D = $Light
@onready var _name_label: Label3D = $NameLabel

var _time := randf() * TAU
var _landed := true
var _base_light := 1.4


func _ready() -> void:
	if slot == null and weapon:
		slot = WeaponSlot.new(weapon)
	if slot == null:
		push_warning("WeaponPickup has no weapon set.")
		queue_free()
		return
	var data := slot.data
	var color := Rarity.color(data.rarity)
	_tint(_beam, "beam_color", color)
	_tint(_ring, "ring_color", color)
	# Rarer weapons get taller beams and brighter light.
	var beam_scale := 0.8 + 0.15 * data.rarity
	_beam.scale = Vector3(1.0, beam_scale, 1.0)
	_beam.position.y = 3.5 * beam_scale
	_light.light_color = color
	_base_light = 1.0 + 0.3 * data.rarity
	_name_label.text = data.display_name
	_name_label.modulate = color
	_name_label.visible = false
	var model := data.build_model()
	model.scale = Vector3.ONE * 1.5
	_visual.add_child(model)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_time += delta
	_visual.rotation.y += delta * 1.3
	_visual.position.y = 0.8 + sin(_time * 2.2) * 0.08
	_light.light_energy = _base_light * (0.85 + 0.15 * sin(_time * 3.0))


## Throws the pickup in an arc from one point to another (loot bursting out of an enemy).
func launch(from: Vector3, to: Vector3, duration := 0.7) -> void:
	_landed = false
	global_position = from
	var tween := create_tween()
	tween.tween_method(_arc.bind(from, to), 0.0, 1.0, duration)
	tween.tween_callback(func() -> void: _landed = true)


func can_be_picked() -> bool:
	return _landed and slot != null


func set_focused(focused: bool) -> void:
	if slot == null:
		return
	_name_label.visible = focused
	_visual.scale = Vector3.ONE * (1.2 if focused else 1.0)


## Removes the pickup and hands over its weapon.
func take() -> WeaponSlot:
	var taken := slot
	slot = null
	Effects.flash(self, global_position + Vector3.UP * 0.8, Rarity.color(taken.data.rarity), 0.8, 0.2)
	queue_free()
	return taken


func _arc(t: float, from: Vector3, to: Vector3) -> void:
	global_position = from.lerp(to, t) + Vector3.UP * 3.0 * 4.0 * t * (1.0 - t)


func _tint(mesh_instance: MeshInstance3D, parameter: String, color: Color) -> void:
	var material := mesh_instance.mesh.surface_get_material(0).duplicate() as ShaderMaterial
	material.set_shader_parameter(parameter, color)
	mesh_instance.material_override = material


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		(body as Player).arsenal.add_nearby(self)


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		(body as Player).arsenal.remove_nearby(self)

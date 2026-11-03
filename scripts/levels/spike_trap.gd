class_name SpikeTrap
extends Area3D
## Hidden floor spikes that teach "keep moving". Step on one and it clicks and glows red; a moment later the
## spikes shoot up and hurt whoever is still standing there. With cycle_time set it also fires on its own,
## so a field of traps with different offsets makes a moving pattern.
## The imported animation retracts the spikes, so extending them plays it backwards.

enum State { HIDDEN, ARMED, UP, COOLDOWN }

@export var damage := 15
## Seconds between being triggered and the spikes coming up.
@export var arm_time := 0.55
@export var up_time := 1.0
@export var cooldown := 0.6
## Above 0, the trap also fires by itself every cycle_time seconds, starting after cycle_offset.
@export var cycle_time := 0.0
@export var cycle_offset := 0.0
## Upward pop given to the player when the spikes hit them.
@export var launch_speed := 6.0

@onready var _model: Node3D = $Model
@onready var _glow: OmniLight3D = $Glow
@onready var _warning: MeshInstance3D = $Warning

var state := State.HIDDEN

var _anim: AnimationPlayer
var _animation := ""
var _time := 0.0
var _cycle := 0.0
var _bodies: Array[Node3D] = []
var _already_hit: Array[Node3D] = []
var _warning_material := StandardMaterial3D.new()


func _ready() -> void:
	_anim = _model.find_children("*", "AnimationPlayer", true, false)[0]
	_animation = _anim.get_animation_list()[0]
	# Start with the spikes hidden: the last frame of the retract animation.
	_anim.play(_animation)
	_anim.seek(_anim.get_animation(_animation).length, true)
	_anim.pause()
	_warning_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_warning_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_warning_material.albedo_color = Color(1, 0.1, 0.05, 0.0)
	_warning.material_override = _warning_material
	_glow.light_energy = 0.0
	_cycle = -cycle_offset
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	_time += delta
	match state:
		State.HIDDEN:
			if cycle_time > 0.0:
				_cycle += delta
				if _cycle >= cycle_time:
					_cycle = 0.0
					_arm()
		State.ARMED:
			var flash := 0.5 + 0.5 * sin(_time * 28.0)
			_warning_material.albedo_color.a = 0.25 + 0.35 * flash
			_glow.light_energy = 2.5 * flash
			if _time >= arm_time:
				_extend()
		State.UP:
			_hurt_bodies()
			if _time >= up_time:
				_retract()
		State.COOLDOWN:
			if _time >= cooldown:
				state = State.HIDDEN
				if not _bodies.is_empty():
					_arm()


func _arm() -> void:
	state = State.ARMED
	_time = 0.0


func _extend() -> void:
	state = State.UP
	_time = 0.0
	_already_hit.clear()
	_anim.play(_animation, -1, -2.5, true)
	_warning_material.albedo_color.a = 0.15
	_glow.light_energy = 1.0


func _retract() -> void:
	state = State.COOLDOWN
	_time = 0.0
	_anim.play(_animation)
	_warning_material.albedo_color.a = 0.0
	_glow.light_energy = 0.0


func _hurt_bodies() -> void:
	# Give the spikes a moment to actually come up before they count.
	if _time < 0.08:
		return
	for body in _bodies:
		if body in _already_hit:
			continue
		_already_hit.append(body)
		var health := Combat.health_of(body)
		if health:
			health.take_damage(damage)
		var player := body as Player
		if player and not player.health.invulnerable:
			player.velocity.y = launch_speed


func _on_body_entered(body: Node3D) -> void:
	if not body in _bodies:
		_bodies.append(body)
	if state == State.HIDDEN:
		_arm()


func _on_body_exited(body: Node3D) -> void:
	_bodies.erase(body)

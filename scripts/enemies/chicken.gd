class_name Chicken
extends Enemy
## The Proving Grounds' first "enemy". Completely harmless: it wanders, pecks at the floor, clucks,
## and runs from the player. The model has no animations, so the waddle and pecking are done in code.

const CLUCKS := ["BAWK!", "bok?", "BAWK BAWK!", "bok bok", "...bawk", "BAAAWK!"]

@export var walk_speed := 1.4
@export var panic_speed := 2.6
@export var panic_distance := 3.5
## How far from its spawn point it wanders.
@export var wander_radius := 3.0

@onready var _model: Node3D = $Model
@onready var _cluck: Label3D = $Cluck

var _home := Vector3.ZERO
var _wander_target := Vector3.ZERO
var _peck_time := 0.0
var _anim_time := 0.0
var _cluck_time := 1.5


func _ready() -> void:
	super()
	_home = global_position
	_wander_target = _home
	_cluck.visible = false


func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	var target_velocity := Vector3.ZERO
	var player := get_player()
	var panicking := false
	if player and player.global_position.distance_to(global_position) < panic_distance:
		var away := global_position - player.global_position
		# Don't run off forever: lean back toward home when far from it.
		away += (_home - global_position) * 0.25
		away.y = 0.0
		target_velocity = away.normalized() * panic_speed
		panicking = true
		_peck_time = 0.0
	elif _peck_time > 0.0:
		_peck_time -= delta
	else:
		var to_target := _wander_target - global_position
		to_target.y = 0.0
		if to_target.length() < 0.4:
			_peck_time = randf_range(0.8, 2.0)
			_pick_wander_target()
		else:
			target_velocity = to_target.normalized() * walk_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, 20.0 * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, 20.0 * delta)
	move_and_slide()
	if is_on_wall():
		_pick_wander_target()
	face(velocity, delta, 12.0)
	_animate(delta, Vector2(velocity.x, velocity.z).length())
	_tick_cluck(delta, panicking)


func _pick_wander_target() -> void:
	_wander_target = _home + Vector3(randf_range(-wander_radius, wander_radius), 0.0, randf_range(-wander_radius, wander_radius))


func _animate(delta: float, speed: float) -> void:
	_anim_time += delta * (5.0 + speed * 5.0)
	var moving := speed > 0.2
	var hop := absf(sin(_anim_time)) * 0.08 if moving else 0.0
	var waddle := sin(_anim_time) * 0.14 if moving else 0.0
	var peck := maxf(0.0, sin(_anim_time * 1.6)) * 0.55 if _peck_time > 0.0 else 0.0
	_model.position.y = hop
	_model.rotation.z = lerpf(_model.rotation.z, waddle, 0.3)
	_model.rotation.x = lerpf(_model.rotation.x, peck, 0.3)


func _tick_cluck(delta: float, panicking: bool) -> void:
	_cluck_time -= delta * (3.0 if panicking else 1.0)
	if _cluck_time > 0.0:
		return
	_cluck_time = randf_range(2.0, 4.0)
	_cluck.text = CLUCKS.pick_random()
	_cluck.visible = true
	_cluck.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(_cluck, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_cluck.hide)


func _die() -> void:
	Effects.flash(self, global_position + Vector3.UP * 0.5, Color(1, 1, 1), 1.4, 0.35)
	Effects.float_text(self, global_position + Vector3.UP * 1.4, "*bawk...*", Color(1, 0.9, 0.7), 0.9)
	queue_free()

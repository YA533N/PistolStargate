class_name Player
extends CharacterBody3D
## Isometric player controller (GDD 13.1): camera-relative movement, jump, dash and mouse aim.
## Weapons live in the Arsenal child (slots, ammo, swapping, pickups). Slide and grapple are not built yet;
## their input actions already exist in the Input Map.
## Values marked "placeholder" are TBD in the GDD and need tuning in playtests.

signal dash_charges_changed(charges: int, max_charges: int)

@export_group("Movement")
## Metres per second. Placeholder.
@export var move_speed := 8.0
@export var ground_acceleration := 70.0
@export var air_acceleration := 35.0

@export_group("Jump")
## Placeholder. With gravity 24 this gives a jump height of about 1.3 m.
@export var jump_velocity := 8.0
@export var gravity := 24.0
@export var max_fall_speed := 30.0

@export_group("Dash")
## GDD: 2 grid units, any direction, on the ground or in the air.
@export var dash_distance_grid := 2.0
@export var dash_duration := 0.12
## Placeholder.
@export var dash_cooldown := 0.6
## GDD: one charge.
@export var max_dash_charges := 1
## Placeholder: invincibility frames for the whole dash.
@export var dash_invulnerable := true

## Falling below this height respawns the player at their start point.
@export var kill_height := -20.0

@onready var health: Health = $Health
@onready var body: Node3D = $Body
@onready var arsenal: Arsenal = $Arsenal

## Where the mouse cursor points on the player's ground plane. Weapons will fire toward it.
var aim_point := Vector3.ZERO
var dash_charges := 0
## Turned off during dialogue. The player still falls and finishes a dash, but ignores move/jump/dash/shoot.
var input_enabled := true

var _dash_time_left := 0.0
var _dash_direction := Vector3.ZERO
var _recharge_time_left := 0.0
var _spawn_position := Vector3.ZERO


func _ready() -> void:
	dash_charges = max_dash_charges
	_spawn_position = global_position
	aim_point = global_position - global_basis.z
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_update_aim()
	_tick_dash_recharge(delta)

	if input_enabled and not is_dashing() and dash_charges > 0 and Input.is_action_just_pressed("dash"):
		_start_dash()

	var was_dashing := is_dashing()
	if was_dashing:
		_process_dash(delta)
	else:
		_process_movement(delta)

	move_and_slide()

	# Ended after moving, so the dash's last partial step still uses dash speed.
	if was_dashing and not is_dashing():
		_end_dash()

	arsenal.update(aim_point, input_enabled, delta)

	if global_position.y < kill_height:
		_respawn()


func is_dashing() -> bool:
	return _dash_time_left > 0.0


## 0 right after a dash, 1 when the next charge is ready. For the HUD.
func dash_recharge_progress() -> float:
	if dash_charges >= max_dash_charges or dash_cooldown <= 0.0:
		return 1.0
	return 1.0 - _recharge_time_left / dash_cooldown


func _process_movement(delta: float) -> void:
	var input := Vector2.ZERO
	if input_enabled:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var target_velocity := _camera_relative(input) * move_speed
	var acceleration := ground_acceleration if is_on_floor() else air_acceleration
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target_velocity, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	if is_on_floor():
		if input_enabled and Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	else:
		velocity.y = maxf(velocity.y - gravity * delta, -max_fall_speed)


func _start_dash() -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := _camera_relative(input)
	if direction == Vector3.ZERO:
		# No movement key held: dash toward where the player is aiming.
		direction = -body.global_basis.z
		direction.y = 0.0
	_dash_direction = direction.normalized()
	_dash_time_left = dash_duration

	if dash_charges == max_dash_charges:
		_recharge_time_left = dash_cooldown
	dash_charges -= 1
	health.invulnerable = dash_invulnerable
	dash_charges_changed.emit(dash_charges, max_dash_charges)


func _process_dash(delta: float) -> void:
	# Scale the last frame's step so the dash covers exactly the set distance.
	var step := minf(delta, _dash_time_left)
	var speed := Grid.to_world(dash_distance_grid) / dash_duration
	# y stays 0, so a dash ignores gravity, including in the air.
	velocity = _dash_direction * (speed * step / delta)
	_dash_time_left -= step


func _end_dash() -> void:
	_dash_time_left = 0.0
	# Keep some momentum instead of stopping dead.
	velocity = _dash_direction * move_speed
	health.invulnerable = false


func _tick_dash_recharge(delta: float) -> void:
	if dash_charges >= max_dash_charges:
		return
	_recharge_time_left -= delta
	if _recharge_time_left <= 0.0:
		dash_charges += 1
		_recharge_time_left = dash_cooldown if dash_charges < max_dash_charges else 0.0
		dash_charges_changed.emit(dash_charges, max_dash_charges)


## Turns WASD input into a world direction, so "up" on the keyboard is "up" on screen.
func _camera_relative(input: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3(input.x, 0.0, input.y)
	var forward := -camera.global_basis.z
	forward.y = 0.0
	var right := camera.global_basis.x
	right.y = 0.0
	return (right.normalized() * input.x - forward.normalized() * input.y).limit_length(1.0)


func _update_aim() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var mouse := get_viewport().get_mouse_position()
	var ground := Plane(Vector3.UP, global_position.y)
	var hit: Variant = ground.intersects_ray(camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))
	if hit == null:
		return
	aim_point = hit
	var look_target := Vector3(aim_point.x, body.global_position.y, aim_point.z)
	if body.global_position.distance_squared_to(look_target) > 0.01:
		body.look_at(look_target, Vector3.UP)


func _respawn() -> void:
	global_position = _spawn_position
	velocity = Vector3.ZERO


func _on_died() -> void:
	# Placeholder until restart/checkpoint behaviour is decided (GDD 13.3).
	get_tree().reload_current_scene.call_deferred()

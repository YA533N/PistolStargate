class_name FirstDescendant
extends Enemy
## Boss of the Proving Grounds: a heavy with a machine gun. It drops in from the sky, walks to mid range,
## then alternates two attacks, each telegraphed by a short wind-up (a red "!" and a flashing light):
##   SWEEP - a spray that sweeps an arc across the player, with gaps to slip through.
##   BURST - three quick aimed bursts at where the player is standing (punishes standing still).
## Bullets leave the gun and dip to knee height, below the top of the low walls: walls and crates are cover,
## and a dash (invincible) or a well-timed jump gets you through.
## Drops ammo at 75% and 50% health and health at 25%, so the fight can't stall when the player runs dry.

enum State { FALLING, LANDED, WALK, WINDUP, SWEEP, BURST, REST, DEAD }

const ANIM_DEATH := "_Action Stash]"
const ANIM_WALK := "_Action Stash]_001"
const ANIM_FIRE := "_Action Stash]_002"
const MUZZLE_BONE := "FX_Muzzle"
## Bullets fly this high above the boss's feet: under the top of the 0.8 m low walls, so they block them.
const BULLET_HEIGHT := 0.5

@export var walk_speed := 2.6
## Distance it tries to keep from the player.
@export var preferred_range := 9.0

@export_group("Gun")
@export var bullet_damage := 6
@export var bullet_speed := 15.0
@export var sweep_rate := 12.0
@export var sweep_duration := 2.0
@export var sweep_arc_degrees := 70.0
@export var burst_count := 3
@export var burst_size := 4
@export var windup_time := 0.7
@export var rest_time := 1.4

@onready var _model: Node3D = $Model
@onready var _warning: Label3D = $Warning
@onready var _warning_light: OmniLight3D = $WarningLight

var state := State.FALLING

var _state_time := 0.0
var _walk_time := 0.0
var _anim: AnimationPlayer
var _muzzle: Node3D
var _gun := WeaponData.new()
var _aim_yaw := 0.0
var _sweep_direction := 1.0
var _shot_timer := 0.0
var _shots_fired := 0
var _next_attack_is_sweep := true
## Health fractions where it drops supplies.
var _drops_left := [0.75, 0.5, 0.25]


func _ready() -> void:
	super()
	health.invulnerable = true
	health.changed.connect(_on_health_changed)
	_gun.damage = bullet_damage
	_gun.projectile_speed = bullet_speed
	_gun.projectile_size = 0.2
	_gun.projectile_color = Color(1, 0.3, 0.15)
	_gun.projectile_range = 40.0
	_anim = _model.find_children("*", "AnimationPlayer", true, false)[0]
	for animation in [ANIM_WALK, ANIM_FIRE]:
		_anim.get_animation(animation).loop_mode = Animation.LOOP_LINEAR
	_anim.play(ANIM_WALK)
	_attach_muzzle()
	_show_warning(false)


func _physics_process(delta: float) -> void:
	_state_time += delta
	apply_gravity(delta)
	var player := get_player()
	match state:
		State.FALLING:
			if is_on_floor():
				_land()
		State.LANDED:
			_set_horizontal(Vector3.ZERO, delta)
			if _state_time > 1.2:
				_enter(State.WALK)
		State.WALK:
			_walk(delta, player)
		State.WINDUP:
			_windup(delta, player)
		State.SWEEP:
			_sweep(delta)
		State.BURST:
			_burst(delta, player)
		State.REST:
			_walk(delta, player, 0.5)
			if _state_time > rest_time:
				_enter(State.WALK)
	move_and_slide()


func _enter(new_state: State) -> void:
	state = new_state
	_state_time = 0.0
	_show_warning(new_state == State.WINDUP)
	match new_state:
		State.WALK:
			_anim.play(ANIM_WALK)
			_walk_time = randf_range(1.2, 2.2)
		State.WINDUP:
			_anim.play(ANIM_FIRE)
			_anim.pause()
		State.SWEEP:
			_anim.play(ANIM_FIRE)
			_shot_timer = 0.0
			_shots_fired = 0
			_aim_yaw = _yaw_to_player() - deg_to_rad(sweep_arc_degrees) * 0.5 * _sweep_direction
		State.BURST:
			_anim.play(ANIM_FIRE)
			_shots_fired = 0
		State.REST:
			_anim.play(ANIM_WALK)


func _land() -> void:
	health.invulnerable = false
	Effects.flash(self, global_position + Vector3.UP * 0.3, Color(1, 0.4, 0.2), 5.0, 0.5)
	Effects.shake(self, 0.8)
	var player := get_player()
	if player and player.global_position.distance_to(global_position) < 3.5:
		player.health.take_damage(15)
	get_tree().call_group("hud", "track_boss", self)
	_enter(State.LANDED)


## Walks to preferred range, strafing once there. speed_scale slows it down while resting.
func _walk(delta: float, player: Player, speed_scale := 1.0) -> void:
	if player == null:
		_set_horizontal(Vector3.ZERO, delta)
		return
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var distance := to_player.length()
	var move := Vector3.ZERO
	if distance > preferred_range + 1.5:
		move = to_player.normalized()
	elif distance < preferred_range - 3.0:
		move = -to_player.normalized()
	else:
		move = to_player.normalized().cross(Vector3.UP) * _sweep_direction * 0.6
	_set_horizontal(move * walk_speed * speed_scale, delta)
	face(to_player, delta, 6.0)
	if state == State.WALK and _state_time > _walk_time:
		_enter(State.WINDUP)


func _windup(delta: float, player: Player) -> void:
	_set_horizontal(Vector3.ZERO, delta)
	if player:
		face(player.global_position - global_position, delta, 8.0)
	_warning_light.light_energy = 3.0 + sin(_state_time * 30.0) * 2.0
	if _state_time >= windup_time:
		_enter(State.SWEEP if _next_attack_is_sweep else State.BURST)
		_next_attack_is_sweep = not _next_attack_is_sweep


func _sweep(delta: float) -> void:
	_set_horizontal(Vector3.ZERO, delta)
	_aim_yaw += _sweep_direction * deg_to_rad(sweep_arc_degrees) / sweep_duration * delta
	rotation.y = _aim_yaw
	_shot_timer -= delta
	while _shot_timer <= 0.0:
		_shot_timer += 1.0 / sweep_rate
		_shots_fired += 1
		# Every 4th bullet is skipped, leaving gaps in the wall of fire.
		if _shots_fired % 4 != 0:
			_shoot(_aim_yaw + randf_range(-0.02, 0.02))
	if _state_time >= sweep_duration:
		_sweep_direction = -_sweep_direction
		_enter(State.REST)


func _burst(delta: float, player: Player) -> void:
	_set_horizontal(Vector3.ZERO, delta)
	if player:
		face(player.global_position - global_position, delta, 10.0)
	var total := burst_count * burst_size
	while _shots_fired < total and _state_time >= _burst_shot_time(_shots_fired):
		_shoot(_yaw_to_player() + randf_range(-0.06, 0.06))
		_shots_fired += 1
	if _shots_fired >= total and _state_time > _burst_shot_time(total - 1) + 0.3:
		_enter(State.REST)


## When the nth bullet of a burst attack is due: bursts 0.45 s apart, bullets 0.07 s apart.
func _burst_shot_time(n: int) -> float:
	return floori(float(n) / burst_size) * 0.45 + (n % burst_size) * 0.07


func _shoot(yaw: float) -> void:
	var direction := Vector3(sin(yaw), 0.0, cos(yaw))
	var bullet := Projectile.new()
	bullet.cruise_height = global_position.y + BULLET_HEIGHT
	get_tree().current_scene.add_child(bullet)
	bullet.launch(_gun, _muzzle.global_position, direction, Combat.ENEMY_SHOT_MASK)
	Effects.flash(self, _muzzle.global_position, _gun.projectile_color, 0.35, 0.06)


## Measured from the muzzle, not the body: the gun is held about 0.6 m to the side, so aiming from the
## body's centre sent every bullet past the player's shoulder. A player closer than the muzzle (it sticks
## out 2.5 m) is aimed at from the body instead, or the shots would turn backwards.
func _yaw_to_player() -> float:
	var player := get_player()
	if player == null:
		return rotation.y
	var from := _muzzle.global_position
	if global_position.distance_to(player.global_position) < global_position.distance_to(from) + 1.0:
		from = global_position
	var offset := player.global_position - from
	return atan2(offset.x, offset.z)


func _set_horizontal(target: Vector3, delta: float) -> void:
	velocity.x = move_toward(velocity.x, target.x, 20.0 * delta)
	velocity.z = move_toward(velocity.z, target.z, 20.0 * delta)


func _show_warning(on: bool) -> void:
	_warning.visible = on
	_warning_light.visible = on


func _attach_muzzle() -> void:
	var skeletons := _model.find_children("*", "Skeleton3D", true, false)
	var skeleton := skeletons[0] as Skeleton3D if not skeletons.is_empty() else null
	if skeleton and skeleton.find_bone(MUZZLE_BONE) >= 0:
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = MUZZLE_BONE
		skeleton.add_child(attachment)
		_muzzle = attachment
	else:
		push_warning("First Descendant model has no %s bone; firing from its chest." % MUZZLE_BONE)
		_muzzle = Marker3D.new()
		_muzzle.position = Vector3(0, 1.4, 1.2)
		add_child(_muzzle)


func _on_health_changed(current: int, maximum: int) -> void:
	while not _drops_left.is_empty() and current > 0 and current <= maximum * _drops_left[0]:
		var threshold: float = _drops_left.pop_front()
		var kind := LootPickup.Kind.HEALTH if threshold <= 0.25 else LootPickup.Kind.AMMO
		for i in 2:
			Loot.spawn_item(self, kind, 25, global_position + Vector3.UP * 2.0, Loot.landing_spot(self, global_position, 2.5, 4.0))
		Effects.float_text(self, global_position + Vector3.UP * 4.4, "ARMOR CRACKED!", Color(1, 0.6, 0.2), 1.1)


func _die() -> void:
	state = State.DEAD
	_show_warning(false)
	set_physics_process(false)
	_anim.play(ANIM_DEATH)
	Effects.shake(self, 0.6)
	# The prize: an Epic or better weapon on top of the normal drop.
	Loot.spawn_weapon(self, WeaponSlot.new(WeaponLibrary.random_drop(Rarity.Tier.EPIC)), global_position + Vector3.UP * 2.0,
		Loot.landing_spot(self, global_position, 2.0, 3.0))
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(self, "position:y", position.y - 3.5, 2.0)
	tween.tween_callback(queue_free)

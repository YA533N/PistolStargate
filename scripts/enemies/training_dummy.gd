class_name TrainingDummy
extends Enemy
## A target for trying weapons out (spawned from the cheat menu). It never moves, shows damage numbers,
## and heals back to full reset_delay seconds after the last hit. It counts as a normal enemy, so the
## Infinite Pistol one-shots it and it counts toward the pistol's recharge when killed.

@export var reset_delay := 3.0

var _since_hit := 0.0


func _ready() -> void:
	super()
	health.damaged.connect(func(_amount: int, _kind: Health.Kind) -> void: _since_hit = 0.0)


func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	move_and_slide()
	_since_hit += delta
	if _since_hit > reset_delay and health.current < health.max_health:
		health.reset()

extends CanvasLayer
## Gameplay HUD: health, dash charge, currencies, current objective and short pop-up messages.
## Ammo and the style meter get added here when weapons and kills exist.

@export var player: Player

@onready var _health_bar: ProgressBar = %HealthBar
@onready var _health_label: Label = %HealthLabel
@onready var _dash_bar: ProgressBar = %DashBar
@onready var _currency_label: Label = %CurrencyLabel
@onready var _objective_label: Label = %ObjectiveLabel
@onready var _message_label: Label = %MessageLabel

var _message_tween: Tween


func _ready() -> void:
	add_to_group("hud")
	_message_label.modulate.a = 0.0
	GameState.currency_changed.connect(_on_currency_changed)
	_on_currency_changed(GameState.weapon_currency, GameState.relic_currency)

	if player == null:
		push_warning("HUD has no player assigned.")
		return
	if not player.is_node_ready():
		await player.ready
	player.health.changed.connect(_on_health_changed)
	_on_health_changed(player.health.current, player.health.max_health)


func _process(_delta: float) -> void:
	if player:
		_dash_bar.value = player.dash_recharge_progress()


func set_objective(text: String) -> void:
	_objective_label.text = text


## Shows text in the middle of the screen for a moment, then fades it out.
func show_message(text: String, duration := 2.5) -> void:
	_message_label.text = text
	if _message_tween:
		_message_tween.kill()
	_message_label.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(duration)
	_message_tween.tween_property(_message_label, "modulate:a", 0.0, 0.5)


func _on_health_changed(current: int, maximum: int) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_label.text = "HP  %d / %d" % [current, maximum]


func _on_currency_changed(weapon: int, relic: int) -> void:
	_currency_label.text = "Weapon $%d     Relic %d" % [weapon, relic]

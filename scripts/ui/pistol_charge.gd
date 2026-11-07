class_name PistolCharge
extends Control
## Top-right HUD row for the Infinite Pistol: one coin per kill it needs (kills_per_charge, 7: the gambler's
## lucky number). Coins are cyan while empty. Each kill with another gun fills the next coin with gold, which
## then hops (the team's Aseprite animation). When the last coin fills, every coin spins like a slot machine
## reel and they stop one by one, left to right, on gold: the pistol is loaded. Firing it empties the row.
## Art: assets/textures/ui/pistol_charge/. Shader: shaders/slot_coin.gdshader. Built by the HUD.

const GOLD := preload("res://assets/textures/ui/pistol_charge/coin_gold.png")
const GOLD_HOP := preload("res://assets/textures/ui/pistol_charge/coin_gold_hop.png")
const EMPTY := preload("res://assets/textures/ui/pistol_charge/coin_empty.png")
const SHADER := preload("res://shaders/slot_coin.gdshader")

## Screen pixels per art pixel.
const PIXEL_SCALE := 4
## Art pixels from one coin to the next (16 px coin, 1 px gap), and the coin sprite's size.
const COIN_STEP := 17
const COIN_SIZE := Vector2(16, 18)
## The Aseprite animation: gold coins rest for 1 s, then hop up a pixel for 0.1 s.
const REST_TIME := 1.0
const HOP_TIME := 0.1
## Seconds for gold to fill a coin, and between coins when several fill at once.
const FILL_TIME := 0.3
const FILL_STAGGER := 0.08
## Slot machine: the first reel spins SPIN_TURNS coins in SPIN_TIME seconds; each reel after it spins
## SPIN_TURNS_STEP more and SPIN_TIME_STEP longer, so they stop left to right. Turns must stay even (gold).
const SPIN_TURNS := 12
const SPIN_TURNS_STEP := 2
const SPIN_TIME := 0.9
const SPIN_TIME_STEP := 0.14
## How fast (coins per second) a reel must spin for full motion blur.
const FULL_BLUR_SPEED := 30.0

var _coins: Array[TextureRect] = []
## Per coin: its gold level (0 to 1), and its reel position now and last frame.
var _fill: Array[float] = []
var _spin: Array[float] = []
var _last_spin: Array[float] = []
## Coins shown (or filling to) gold.
var _filled := 0
var _shown_once := false
## Set by Arsenal.pistol_charged: the next refresh plays the slot machine.
var _jackpot_pending := false
var _spinning := false
var _idle_time := 0.0
## Running fill and spin animations, stopped when the row resets.
var _tweens: Array[Tween] = []


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false


## Hooks the row to the player's weapons. Called once by the HUD.
func watch(arsenal: Arsenal) -> void:
	arsenal.pistol_charged.connect(func() -> void: _jackpot_pending = true)


func refresh(arsenal: Arsenal) -> void:
	visible = arsenal.pistol != null
	if not visible:
		_shown_once = false
		return
	var count := arsenal.pistol.data.kills_per_charge
	if count != _coins.size():
		_build(count)
	var loaded := not arsenal.pistol.is_out_of_ammo()
	var target := count if loaded else mini(arsenal.pistol_kills, count)
	if not _shown_once:
		# First time on screen (level loaded): show the current charge without animating.
		_shown_once = true
		_jackpot_pending = false
		_filled = target
		for i in count:
			_set_fill(1.0 if i < target else 0.0, i)
		return
	if target < _filled:
		# Fired (or reset): every coin goes back to cyan.
		for tween in _tweens:
			tween.kill()
		_tweens.clear()
		_stop_spin()
		for i in count:
			_set_fill(1.0 if i < target else 0.0, i)
		_filled = target
	var delay := 0.0
	for i in range(_filled, target):
		var tween := _new_tween()
		tween.tween_interval(delay)
		tween.tween_method(_set_fill.bind(i), 0.0, 1.0, FILL_TIME)
		tween.tween_callback(_hop.bind(i))
		delay += FILL_STAGGER
	_filled = target
	if loaded and _jackpot_pending:
		_jackpot_pending = false
		_new_tween().tween_interval(delay + FILL_TIME + 0.1).finished.connect(_play_slot_machine)


func _process(delta: float) -> void:
	if not visible:
		return
	# Idle hop from the Aseprite file, for every full gold coin.
	_idle_time = fmod(_idle_time + delta, REST_TIME + HOP_TIME)
	var hopping := _idle_time >= REST_TIME and not _spinning
	for i in _coins.size():
		var material := _coins[i].material as ShaderMaterial
		if _fill[i] >= 1.0 and not _coins[i].has_meta("hop"):
			material.set_shader_parameter("gold_tex", GOLD_HOP if hopping else GOLD)
		# Motion blur follows how fast each reel turns.
		var speed := absf(_spin[i] - _last_spin[i]) / maxf(delta, 0.001)
		_last_spin[i] = _spin[i]
		material.set_shader_parameter("blur", clampf(speed / FULL_BLUR_SPEED, 0.0, 1.0))


func _build(count: int) -> void:
	for coin in _coins:
		coin.queue_free()
	_coins.clear()
	_fill.clear()
	_spin.clear()
	_last_spin.clear()
	var coin_size := COIN_SIZE * PIXEL_SCALE
	for i in count:
		var coin := TextureRect.new()
		coin.texture = GOLD
		coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		coin.stretch_mode = TextureRect.STRETCH_SCALE
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.mouse_filter = MOUSE_FILTER_IGNORE
		coin.position = Vector2(i * COIN_STEP * PIXEL_SCALE, 0)
		coin.size = coin_size
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter("gold_tex", GOLD)
		material.set_shader_parameter("empty_tex", EMPTY)
		coin.material = material
		add_child(coin)
		_coins.append(coin)
		_fill.append(0.0)
		_spin.append(0.0)
		_last_spin.append(0.0)
	custom_minimum_size = Vector2(((count - 1) * COIN_STEP + COIN_SIZE.x) * PIXEL_SCALE, coin_size.y)


func _set_fill(value: float, index: int) -> void:
	_fill[index] = value
	(_coins[index].material as ShaderMaterial).set_shader_parameter("fill", value)


## A coin that just turned gold hops once, like the Aseprite's second frame.
func _hop(index: int) -> void:
	var material := _coins[index].material as ShaderMaterial
	_coins[index].set_meta("hop", true)
	material.set_shader_parameter("gold_tex", GOLD_HOP)
	await get_tree().create_timer(HOP_TIME).timeout
	if is_instance_valid(_coins[index]):
		_coins[index].remove_meta("hop")
		material.set_shader_parameter("gold_tex", GOLD)


## All coins spin like slot machine reels and stop left to right on gold, each with a small bounce and a flash.
func _play_slot_machine() -> void:
	if _filled < _coins.size():
		return
	_spinning = true
	for i in _coins.size():
		var material := _coins[i].material as ShaderMaterial
		var turns := float(SPIN_TURNS + SPIN_TURNS_STEP * i)
		_spin[i] = 0.0
		_last_spin[i] = 0.0
		material.set_shader_parameter("reel", 1.0)
		var tween := _new_tween()
		tween.tween_method(_set_spin.bind(i), 0.0, turns + 0.15, SPIN_TIME + SPIN_TIME_STEP * i) \
				.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_method(_set_spin.bind(i), turns + 0.15, turns, 0.12).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(material.set_shader_parameter.bind("flash", 1.0))
		tween.tween_method(func(v: float) -> void: material.set_shader_parameter("flash", v), 1.0, 0.0, 0.3)
		tween.parallel().tween_method(func(v: float) -> void: material.set_shader_parameter("reel", v), 1.0, 0.0, 0.15)
		if i == _coins.size() - 1:
			tween.tween_callback(_stop_spin)


func _new_tween() -> Tween:
	for i in range(_tweens.size() - 1, -1, -1):
		if not _tweens[i].is_valid():
			_tweens.remove_at(i)
	var tween := create_tween()
	_tweens.append(tween)
	return tween


func _set_spin(value: float, index: int) -> void:
	_spin[index] = value
	(_coins[index].material as ShaderMaterial).set_shader_parameter("spin", value)


func _stop_spin() -> void:
	_spinning = false
	for i in _coins.size():
		var material := _coins[i].material as ShaderMaterial
		_spin[i] = 0.0
		_last_spin[i] = 0.0
		material.set_shader_parameter("spin", 0.0)
		material.set_shader_parameter("reel", 0.0)
		material.set_shader_parameter("flash", 0.0)

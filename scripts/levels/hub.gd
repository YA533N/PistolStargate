extends Node3D
## Level 1, the hub (GDD 14.2): teaches movement before the arena.
## The shop and shooting range from the GDD are not built yet.
func _ready() -> void:
	AudioManager.play_music(preload("res://assets/audio/music/CasinoJazz.mp3"))

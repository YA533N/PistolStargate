extends Node

const SFX = {
	"health_pickup": preload("res://assets/audio/sfx/HealthPickup.mp3"),
	"weapon_pickup": preload("res://assets/audio/sfx/WeaponPickup.mp3"),
	"pistol_reload": preload("res://assets/audio/sfx/PistolReload.mp3"),
	"shotgun_reload": preload("res://assets/audio/sfx/ShotgunReload.mp3"),
}

func play_sfx(sfx_name: String, volume_db: float = 0.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = SFX[sfx_name]
	p.volume_db = volume_db
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

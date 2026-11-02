class_name Portal
extends Area3D
## Moves the player to another scene when they walk in (GDD 14.4: areas connect through portals).
## Leave target_scene empty for a portal that isn't open yet; it shows locked_message instead.

@export_file("*.tscn") var target_scene := ""
@export var locked_message := "This portal is not open yet."


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body is Player:
		return
	if target_scene.is_empty():
		get_tree().call_group("hud", "show_message", locked_message)
		return
	get_tree().change_scene_to_file.call_deferred(target_scene)

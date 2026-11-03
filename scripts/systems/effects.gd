class_name Effects
## Small throwaway visuals made in code: flashes, lightning, beams and floating damage numbers.
## Everything here frees itself when its tween ends.

static var _materials := {}


## Unshaded glowing material, cached per colour so hundreds of bullets share a few materials.
static func glow_material(color: Color, transparent := false) -> StandardMaterial3D:
	var key := "%s|%s" % [color, transparent]
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = color
		if transparent:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			material.no_depth_test = false
		material.disable_receive_shadows = true
		_materials[key] = material
	return _materials[key]


## A sphere that grows and fades: muzzle flashes, explosions, spawn and teleport puffs.
static func flash(context: Node, position: Vector3, color: Color, radius := 1.0, duration := 0.3) -> void:
	var root := _root(context)
	if root == null:
		return
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var material := glow_material(color, true).duplicate() as StandardMaterial3D
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(instance)
	instance.global_position = position
	instance.scale = Vector3.ONE * radius * 0.3
	var tween := instance.create_tween().set_parallel()
	tween.tween_property(instance, "scale", Vector3.ONE * radius, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(material, "albedo_color:a", 0.0, duration)
	tween.chain().tween_callback(instance.queue_free)


## A straight glowing line from a to b (railgun beam, lightning arcs).
static func beam(context: Node, a: Vector3, b: Vector3, color: Color, width := 0.12, duration := 0.25) -> void:
	var root := _root(context)
	var length := a.distance_to(b)
	if root == null or length < 0.01:
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, width, length)
	var material := glow_material(color, true).duplicate() as StandardMaterial3D
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(instance)
	instance.global_position = (a + b) * 0.5
	var up := Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT
	instance.look_at(b, up)
	var tween := instance.create_tween().set_parallel()
	tween.tween_property(material, "albedo_color:a", 0.0, duration)
	tween.tween_property(instance, "scale", Vector3(0.2, 0.2, 1.0), duration)
	tween.chain().tween_callback(instance.queue_free)


## Jagged lightning between two points, built from a few short beams.
static func lightning(context: Node, a: Vector3, b: Vector3, color: Color, duration := 0.22) -> void:
	var points := [a]
	var segments := 5
	for i in range(1, segments):
		var t := float(i) / segments
		var jitter := Vector3(randf_range(-0.35, 0.35), randf_range(-0.2, 0.2), randf_range(-0.35, 0.35))
		points.append(a.lerp(b, t) + jitter)
	points.append(b)
	for i in points.size() - 1:
		beam(context, points[i], points[i + 1], color, 0.07, duration)


## Floating text that rises and fades, e.g. damage numbers.
static func float_text(context: Node, position: Vector3, text: String, color: Color, size := 1.0) -> void:
	var root := _root(context)
	if root == null:
		return
	var label := Label3D.new()
	label.text = text
	label.modulate = color
	label.outline_modulate = Color(0, 0, 0, 0.85)
	label.font_size = int(56 * size)
	label.outline_size = int(14 * size)
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 10
	root.add_child(label)
	label.global_position = position + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "global_position:y", label.global_position.y + 1.4, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.45)
	tween.chain().tween_callback(label.queue_free)


## Shakes every camera rig in the scene.
static func shake(context: Node, strength := 0.3) -> void:
	if context.is_inside_tree():
		context.get_tree().call_group("camera_rig", "shake", strength)


static func _root(context: Node) -> Node:
	if context == null or not context.is_inside_tree():
		return null
	var tree := context.get_tree()
	return tree.current_scene if tree.current_scene else tree.root

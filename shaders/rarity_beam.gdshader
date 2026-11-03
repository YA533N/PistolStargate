// Vertical light beam above a weapon on the floor, tinted by rarity (looter-shooter style).
// Used on an uncapped CylinderMesh. Bright in the middle of the cylinder, fading toward the top.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 beam_color : source_color = vec4(1.0);
uniform float intensity = 1.6;
// Must match the mesh height so the fade spans the whole beam.
uniform float height = 7.0;

varying float v_height;

void vertex() {
	v_height = clamp(VERTEX.y / height + 0.5, 0.0, 1.0);
}

void fragment() {
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float core = pow(facing, 2.0);
	float fade = pow(1.0 - v_height, 1.6);
	float stripes = 0.75 + 0.25 * sin(v_height * 40.0 - TIME * 5.0);
	ALBEDO = beam_color.rgb * intensity * core * fade * stripes;
}

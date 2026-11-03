// Pulsing ring of light on the floor under a dropped weapon, tinted by rarity. Used on a PlaneMesh.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 ring_color : source_color = vec4(1.0);
uniform float intensity = 1.5;

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float ring = smoothstep(1.0, 0.9, d) * smoothstep(0.55, 0.9, d);
	float glow = (1.0 - smoothstep(0.0, 1.0, d)) * 0.35;
	float pulse = 0.75 + 0.25 * sin(TIME * 3.0);
	ALBEDO = ring_color.rgb * intensity * (ring + glow) * pulse;
}

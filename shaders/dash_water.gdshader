// The green dash block on the HUD, refilling like water: a wavy surface with a light foam line rises
// from the bottom as level goes from 0 to 1. The waves calm down near empty and full, so a full block is solid.
shader_type canvas_item;

uniform float level : hint_range(0.0, 1.0) = 1.0;
uniform vec4 foam_color : source_color = vec4(0.72, 1.0, 0.86, 1.0);
uniform vec4 deep_color : source_color = vec4(0.04, 0.55, 0.32, 1.0);
uniform float wave_height = 0.07;
uniform float wave_speed = 7.0;

void fragment() {
	// Snap to the sprite's pixels so the water stays crisp pixel art.
	vec2 uv = (floor(UV / TEXTURE_PIXEL_SIZE) + 0.5) * TEXTURE_PIXEL_SIZE;
	float calm = smoothstep(1.0, 0.92, level) * smoothstep(0.0, 0.08, level);
	float wave = 0.6 * sin(uv.x * 14.0 + TIME * wave_speed) + 0.4 * sin(uv.x * 25.0 - TIME * wave_speed * 1.4);
	float surface = 1.0 - level + wave * wave_height * calm;
	float depth = uv.y - surface;
	vec4 tex = texture(TEXTURE, UV);
	if (depth < 0.0) {
		COLOR.a = 0.0;
	} else if (level < 1.0 && depth < TEXTURE_PIXEL_SIZE.y * 3.0) {
		COLOR = vec4(foam_color.rgb, tex.a * COLOR.a);
	} else if (level < 1.0) {
		// Darker towards the bottom while filling, like deeper water.
		COLOR.rgb = mix(COLOR.rgb, deep_color.rgb, clamp(uv.y - surface, 0.0, 1.0) * 0.5);
	}
}

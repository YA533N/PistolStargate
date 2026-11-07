// One red segment of the HUD health bar. Drains from its right edge as fill drops, with the cut slanted
// like the segment's sides. Health just lost stays pale (ghost) until the HUD catches it up to fill.
shader_type canvas_item;

uniform float fill : hint_range(0.0, 1.0) = 1.0;
uniform float ghost : hint_range(0.0, 1.0) = 1.0;
// How far the bottom edge sits right of the top edge, as a fraction of the texture's width.
uniform float slant = 0.0;
uniform vec4 ghost_color : source_color = vec4(1.0, 0.86, 0.8, 1.0);

void fragment() {
	// Snap to the sprite's pixels so the cut stays crisp pixel art.
	vec2 uv = (floor(UV / TEXTURE_PIXEL_SIZE) + 0.5) * TEXTURE_PIXEL_SIZE;
	float along = (uv.x - slant * uv.y) / max(1.0 - slant, 0.001);
	vec4 tex = texture(TEXTURE, UV);
	// Exact when full or empty: the sides aren't perfectly parallel, so the slanted cut alone would clip a corner.
	float shown = fill >= 0.999 ? 2.0 : (fill <= 0.001 ? -2.0 : fill);
	float pale = ghost >= 0.999 ? 2.0 : (ghost <= 0.001 ? -2.0 : ghost);
	if (along > max(shown, pale)) {
		COLOR.a = 0.0;
	} else if (along > shown) {
		COLOR = vec4(ghost_color.rgb, tex.a * COLOR.a);
	}
}

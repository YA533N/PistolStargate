// One coin of the Infinite Pistol charge row (top right of the HUD, see PistolCharge).
//   fill: gold rises from the bottom like liquid when a kill lands (0 = cyan coin, 1 = gold coin).
//   reel/spin: when all coins are gold the coin becomes a slot machine reel. The reel is a drum of gold and
//   cyan coins taking turns; spin scrolls it down (in coins), reel bends and shades it like a real drum, and
//   blur smears it while it spins fast. An even whole spin lands on a gold coin.
//   flash: whitens the coin, used when a reel stops.
shader_type canvas_item;

uniform sampler2D gold_tex : filter_nearest;
uniform sampler2D empty_tex : filter_nearest;
uniform float fill : hint_range(0.0, 1.0) = 0.0;
uniform float spin = 0.0;
uniform float reel : hint_range(0.0, 1.0) = 0.0;
uniform float blur : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 liquid_top : source_color = vec4(1.0, 0.99, 0.72, 1.0);

// The reel at height y (in coins): even coins are gold, odd coins are cyan.
vec4 reel_coin(float x, float y) {
	vec2 p = vec2(x, fract(y));
	return mod(floor(y), 2.0) < 0.5 ? texture(gold_tex, p) : texture(empty_tex, p);
}

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	// Snap to the sprite's pixels so it stays crisp pixel art.
	vec2 uv = (floor(UV / px) + 0.5) * px;
	vec4 col;
	if (reel > 0.0) {
		// -1 at the top of the window, 1 at the bottom. The drum squashes coins near the edges.
		float yc = UV.y * 2.0 - 1.0;
		float bent = asin(clamp(yc * 0.85, -1.0, 1.0)) / asin(0.85);
		float y = mix(yc, bent, reel) * 0.5 + 0.5 - spin;
		col = vec4(0.0);
		for (int i = 0; i < 5; i++) {
			col += reel_coin(uv.x, y + (float(i) / 4.0 - 0.5) * blur * 0.7);
		}
		col /= 5.0;
		col.rgb *= 1.0 - 0.55 * reel * yc * yc;
	} else {
		vec4 gold = texture(gold_tex, uv);
		col = texture(empty_tex, uv);
		if (fill >= 1.0) {
			col = gold;
		} else if (fill > 0.0) {
			// The coin covers sprite rows 1 to 17; the wavy gold surface rises through them.
			float wave = 0.6 * sin(uv.x * 18.0 + TIME * 9.0) + 0.4 * sin(uv.x * 31.0 - TIME * 13.0);
			float surface = (mix(17.0, 1.0, fill) + wave * 1.2) * px.y;
			if (uv.y > surface && gold.a > 0.0) {
				col = gold;
				bool outline = dot(gold.rgb, vec3(1.0)) < 0.2;
				if (!outline && uv.y < surface + px.y * 1.5) {
					col.rgb = liquid_top.rgb;
				}
			}
		}
	}
	col.rgb = mix(col.rgb, vec3(1.0), flash);
	COLOR = col;
}

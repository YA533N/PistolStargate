
shader_type canvas_item;
uniform sampler2D clouds:source_color;
uniform sampler2D dither_areas:source_color;
uniform sampler2D rifts:source_color;
uniform sampler2D stars:source_color;
uniform sampler2D star_cells:source_color;
uniform sampler2D color_ramp:source_color;
uniform float steps = 8;
uniform float edge_size:hint_range(0,1.) = .01;

// these dithering and decimate functions were likely pulled from lygia, if I remember correctly. Been floating around in my shader files for a while.
#define DITHER_BAYER_PRECISION 2
vec3 decimate(vec3 v, float p){ return floor(v*p)/p; }
float ditherBayer(const in vec2 xy) {
    float kern[64];
    kern[ 0] = 0.000; kern[ 1] = 0.500; kern[ 2] = 0.124; kern[ 3] = 0.624; kern[ 4] = 0.028; kern[ 5] = 0.532; kern[ 6] = 0.156; kern[ 7] = 0.656;
    kern[ 8] = 0.752; kern[ 9] = 0.248; kern[10] = 0.876; kern[11] = 0.376; kern[12] = 0.784; kern[13] = 0.280; kern[14] = 0.908; kern[15] = 0.404;
    kern[16] = 0.188; kern[17] = 0.688; kern[18] = 0.060; kern[19] = 0.564; kern[20] = 0.216; kern[21] = 0.720; kern[22] = 0.092; kern[23] = 0.596;
    kern[24] = 0.940; kern[25] = 0.436; kern[26] = 0.812; kern[27] = 0.312; kern[28] = 0.972; kern[29] = 0.468; kern[30] = 0.844; kern[31] = 0.344;
    kern[32] = 0.044; kern[33] = 0.548; kern[34] = 0.172; kern[35] = 0.672; kern[36] = 0.012; kern[37] = 0.516; kern[38] = 0.140; kern[39] = 0.640;
    kern[40] = 0.800; kern[41] = 0.296; kern[42] = 0.924; kern[43] = 0.420; kern[44] = 0.768; kern[45] = 0.264; kern[46] = 0.892; kern[47] = 0.392;
    kern[48] = 0.232; kern[49] = 0.736; kern[50] = 0.108; kern[51] = 0.608; kern[52] = 0.200; kern[53] = 0.704; kern[54] = 0.076; kern[55] = 0.580;
    kern[56] = 0.988; kern[57] = 0.484; kern[58] = 0.860; kern[59] = 0.360; kern[60] = 0.956; kern[61] = 0.452; kern[62] = 0.828; kern[63] = 0.328;
    int index = int(mod(xy.x, 8.0)) + (int(mod(xy.y, 8.0)) * 8);
    return kern[index];
}
vec3 ditherBayer(vec3 color, const in vec2 xy, const int pres) {
    float d = float(pres);
    vec3 decimated = decimate(color, d);
    vec3 diff = (color - decimated) * d;
    vec3 ditherPattern = vec3(ditherBayer(xy));
    return decimate(color + (step(ditherPattern, diff) / d), d);
}
float ditherBayer(const in float val, const in vec2 xy) { return ditherBayer(vec3(val), xy, DITHER_BAYER_PRECISION).r; }

float get_star(in vec2 uv){

	float star_flare = texture(stars, uv).r;
	float star_cell = texture(star_cells, uv).r;
	star_flare = star_flare * clamp(sin((TIME/10.+star_cell*PI*2.))*100.-99., star_cell*.005, 1);

	return star_flare;
}

void fragment() {
	// Called for every pixel the material is visible on.
	// 1. Planning + 2. Cloud up
	// A cellular noise can make some convincing cloud shapes.
	vec3 cloud = texture(clouds, UV).rgb;
	
	// 3. Dither, 4. Layers
	// figure out the edges, by first doing a bit of posterization
	vec3 edges = decimate(cloud+edge_size, steps);
	cloud = decimate(cloud, steps);
	// mask out an area to dither
	vec3 dither_area = texture(dither_areas, UV).rgb;
	float dither_value = ditherBayer(dither_area.r, FRAGCOORD.xy);
	// multiply the dither area with the edges,
	float should_dither = clamp(sign(edges.r-cloud.r),0,1);
	should_dither *= dither_value;
	
	// 5. Rift!
	vec3 rift = texture(rifts, UV).rgb;
	float rift_mask = decimate(rift, 2).r;
	float rift_edge = step(.5, rift_mask) - rift_mask;
	rift_mask = step(.6,rift_mask);
	cloud.r = max(0, cloud.r-rift_mask);
	cloud.r = mix(cloud.r, cloud.r * 3., rift_edge);
	// Apply the dithering to our cloud effect!
	cloud = mix(cloud, vec3(cloud.r+1./steps), should_dither);
	float star = get_star(UV);
	cloud = mix(texture(color_ramp, vec2(cloud.r, 0)).rgb, vec3(1.), smoothstep(.5,1., star));
	COLOR.rgb = cloud.rgb;
}

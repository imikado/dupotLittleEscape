// Cartoon look: flat color bands from a fixed light direction, no engine lighting.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, hint_default_white, filter_linear_mipmap;

// world space direction towards the fake light
uniform vec3 light_direction = vec3(0.45, 1.0, 0.3);
// darkness of the shadowed band (0 = no shading)
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.32;
// cartoon shadows are not just darker: they shift to a cool hue (multiplied with the color)
uniform vec4 shadow_tint : source_color = vec4(0.78, 0.74, 0.96, 1.0);
// lit faces get a slightly warm tint
uniform vec4 light_tint : source_color = vec4(1.0, 0.97, 0.9, 1.0);
// faces turned to the light get a flat highlight band
uniform float highlight_strength : hint_range(0.0, 1.0) = 0.08;
// width of the transition between bands (small = sharp edges, bigger = soft cartoon shading)
uniform float band_smoothness : hint_range(0.0, 0.3) = 0.1;
// light edge on silhouettes
uniform float rim_strength : hint_range(0.0, 1.0) = 0.1;
// more vivid colors (1 = original)
uniform float saturation : hint_range(0.0, 2.0) = 1.15;
uniform float brightness : hint_range(0.0, 2.0) = 0.95;

// optional per room colors (walls, floor): rect = (min x, min z, max x, max z) in world space,
// the first rect containing the fragment replaces albedo (colors are linear)
uniform int zone_count = 0;
uniform vec4 zone_rects[4];
uniform vec4 zone_colors[4];

// optional second color for the raised parts of a mesh (vertices above raised_height in
// model space), e.g. the letters and digits engraved on the chessboard border
uniform float raised_height = 100000.0;
uniform vec4 raised_color : source_color = vec4(1.0);

varying vec3 world_position;
varying float model_height;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	model_height = VERTEX.y;
}

vec3 saturate_color(vec3 color, float amount) {
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	return max(mix(vec3(luma), color, amount), vec3(0.0));
}

void fragment() {
	vec3 color = albedo.rgb;
	for (int i = 0; i < zone_count; i++) {
		vec4 rect = zone_rects[i];
		if (world_position.x >= rect.x && world_position.z >= rect.y && world_position.x < rect.z && world_position.z < rect.w) {
			color = zone_colors[i].rgb;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
			// zone colors are linear, the Compatibility renderer works in sRGB space
			color = mix(color * 12.92, 1.055 * pow(color, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), color));
#endif
			break;
		}
	}
	if (model_height > raised_height) {
		color = raised_color.rgb;
	}
	vec3 base = color * texture(texture_albedo, UV).rgb;

	// per face normal from the real geometry (view space): the imported normals are smoothed
	// across the door holes / buttons cuts, which drew diagonal bands and lines on flat surfaces
	vec3 face_normal = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (dot(face_normal, VIEW) < 0.0) {
		face_normal = -face_normal;
	}
	// also used by the outline post-process (normal buffer)
	NORMAL = face_normal;

	vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(face_normal, 0.0)).xyz);
	float ndl = dot(world_normal, normalize(light_direction));

	// 3 bands: lit / mid / shadow, plus a highlight on the faces turned to the light
	float lit = smoothstep(0.25 - band_smoothness, 0.25 + band_smoothness, ndl);
	float mid = smoothstep(-0.35 - band_smoothness, -0.35 + band_smoothness, ndl);
	float highlight = smoothstep(0.85 - band_smoothness, 0.85 + band_smoothness, ndl);

	// shadow = darker and hue shifted, the mid band halfway
	vec3 shadow = mix(vec3(1.0), shadow_tint.rgb, shadow_strength * 1.6) * (1.0 - shadow_strength * 0.4);
	vec3 half_shadow = mix(vec3(1.0), shadow, 0.45);
	vec3 shade = mix(shadow, mix(half_shadow, light_tint.rgb, lit), mid);

	float rim = pow(1.0 - clamp(dot(face_normal, VIEW), 0.0, 1.0), 4.0) * rim_strength;

	// saturated after the shading: cartoon shadows stay vivid instead of turning grey
	vec3 lit_color = saturate_color(base * shade * brightness, mix(saturation * 1.15, saturation, lit)) + base * rim;
	// highlight: toward white, so dark colors get it too
	ALBEDO = mix(lit_color, vec3(1.0), highlight * highlight_strength * lit);
}

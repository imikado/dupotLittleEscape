// Cartoon look: flat color bands from a fixed light direction, no engine lighting.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, hint_default_white, filter_linear_mipmap;

// world space direction towards the fake light
uniform vec3 light_direction = vec3(0.45, 1.0, 0.3);
// darkness of the shadowed band (0 = no shading)
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.35;
// width of the transition between bands (small = sharp cartoon edges)
uniform float band_smoothness : hint_range(0.0, 0.3) = 0.03;
// light edge on silhouettes
uniform float rim_strength : hint_range(0.0, 1.0) = 0.12;
uniform float brightness : hint_range(0.0, 2.0) = 0.85;

// optional per room colors (walls, floor): rect = (min x, min z, max x, max z) in world space,
// the first rect containing the fragment replaces albedo (colors are linear)
uniform int zone_count = 0;
uniform vec4 zone_rects[4];
uniform vec4 zone_colors[4];

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
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

	// 3 bands: lit / mid / shadow
	float lit = smoothstep(0.25 - band_smoothness, 0.25 + band_smoothness, ndl);
	float mid = smoothstep(-0.35 - band_smoothness, -0.35 + band_smoothness, ndl);
	float shade = mix(1.0 - shadow_strength, mix(1.0 - shadow_strength * 0.45, 1.0, lit), mid);

	float rim = pow(1.0 - clamp(dot(face_normal, VIEW), 0.0, 1.0), 4.0) * rim_strength;

	ALBEDO = base * (shade * brightness + rim);
}

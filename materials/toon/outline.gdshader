// Cartoon outlines as a screen post-process: a full screen quad attached to the camera
// draws a line where the depth or the surface orientation changes suddenly.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D normal_texture : hint_normal_roughness_texture, filter_nearest, repeat_disable;

uniform vec4 outline_color : source_color = vec4(0.07, 0.05, 0.1, 1.0);
// thickness in pixels for a 600 pixels high screen
uniform float thickness : hint_range(0.5, 5.0) = 1.2;
// relative depth gap (silhouettes)
uniform float depth_threshold : hint_range(0.0, 1.0) = 0.08;
// angle between surfaces (creases), 1 - cos(angle)
uniform float normal_threshold : hint_range(0.0, 2.0) = 0.6;
// lines fade out with the distance (the fog hides the room anyway)
uniform float fade_start = 7.0;
uniform float fade_end = 12.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_projection) {
	float depth = texture(depth_texture, uv).r;
	vec4 view = inv_projection * vec4(uv * 2.0 - 1.0, depth, 1.0);
	return -view.z / view.w;
}

vec3 view_normal(vec2 uv) {
	return texture(normal_texture, uv).xyz * 2.0 - 1.0;
}

void fragment() {
	vec2 pixel = thickness * (VIEWPORT_SIZE.y / 600.0) / VIEWPORT_SIZE;
	vec2 offsets[4] = vec2[](vec2(pixel.x, 0.0), vec2(-pixel.x, 0.0), vec2(0.0, pixel.y), vec2(0.0, -pixel.y));

	float center_depth = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 center_normal = view_normal(SCREEN_UV);

	float depths[4];
	for (int i = 0; i < 4; i++) {
		depths[i] = linear_depth(SCREEN_UV + offsets[i], INV_PROJECTION_MATRIX);
	}

	float edge = 0.0;
	for (int i = 0; i < 4; i++) {
		float depth = depths[i];
		// opposite neighbour (offsets go by pairs: +x/-x, +y/-y)
		float opposite = depths[i ^ 1];
		// on a plane 1/depth is linear on screen: a surface seen almost edge-on has big depth gaps
		// between pixels but stays planar, only a real silhouette breaks the plane
		float plane_error = abs(center_depth / depth + center_depth / opposite - 2.0);
		// only the far side of a silhouette gets the line, so it stays thin
		float depth_edge = step(depth_threshold, (depth - center_depth) / center_depth) * step(depth_threshold * 0.5, plane_error);
		float normal_edge = step(normal_threshold, 1.0 - dot(center_normal, view_normal(SCREEN_UV + offsets[i])));
		edge = max(edge, max(depth_edge, normal_edge));
	}

	float fade = 1.0 - smoothstep(fade_start, fade_end, center_depth);
	ALBEDO = outline_color.rgb;
	ALPHA = edge * fade * outline_color.a;
}

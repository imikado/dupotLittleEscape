// Cartoon outlines for the Compatibility renderer (Web export): same post-process as
// outline.gdshader but based on the depth only (no normal buffer in Compatibility).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest, repeat_disable;

uniform vec4 outline_color : source_color = vec4(0.07, 0.05, 0.1, 1.0);
// thickness in pixels for a 600 pixels high screen
uniform float thickness : hint_range(0.5, 5.0) = 1.2;
// relative depth gap (silhouettes)
uniform float depth_threshold : hint_range(0.0, 1.0) = 0.08;
// creases: the depth slope changes suddenly between both sides of the pixel
uniform float crease_threshold : hint_range(0.0, 1.0) = 0.25;
// lines fade out with the distance (the fog hides the room anyway)
uniform float fade_start = 7.0;
uniform float fade_end = 12.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_projection) {
	// OpenGL: depth buffer in [0, 1] -> NDC z in [-1, 1]
	float depth = texture(depth_texture, uv).r * 2.0 - 1.0;
	vec4 view = inv_projection * vec4(uv * 2.0 - 1.0, depth, 1.0);
	return -view.z / view.w;
}

void fragment() {
	vec2 pixel = thickness * (VIEWPORT_SIZE.y / 600.0) / VIEWPORT_SIZE;

	float center = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	float left = linear_depth(SCREEN_UV - vec2(pixel.x, 0.0), INV_PROJECTION_MATRIX);
	float right = linear_depth(SCREEN_UV + vec2(pixel.x, 0.0), INV_PROJECTION_MATRIX);
	float down = linear_depth(SCREEN_UV - vec2(0.0, pixel.y), INV_PROJECTION_MATRIX);
	float up = linear_depth(SCREEN_UV + vec2(0.0, pixel.y), INV_PROJECTION_MATRIX);

	// silhouettes: a neighbour is much farther
	float far_gap = max(max(left, right), max(down, up)) - center;
	float edge = step(depth_threshold, far_gap / center);

	// creases: second derivative of the depth (flat surfaces give ~0, even when inclined)
	float crease = max(abs(left + right - 2.0 * center), abs(down + up - 2.0 * center)) / center;
	edge = max(edge, step(crease_threshold * 0.1, crease));

	float fade = 1.0 - smoothstep(fade_start, fade_end, center);
	ALBEDO = outline_color.rgb;
	ALPHA = edge * fade * outline_color.a;
}

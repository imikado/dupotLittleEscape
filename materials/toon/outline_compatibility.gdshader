// Cartoon outlines for the Compatibility renderer (Web export): same post-process as
// outline.gdshader but based on the depth only (no normal buffer in Compatibility).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

uniform vec4 outline_color : source_color = vec4(0.07, 0.05, 0.1, 1.0);
// cartoon lines: a darker shade of the underlying color instead of a flat black
uniform float line_tint : hint_range(0.0, 1.0) = 0.7;
uniform float line_darkness : hint_range(0.0, 1.0) = 0.35;
// thickness in pixels for a 600 pixels high screen: silhouettes are bolder than the inner lines
uniform float thickness : hint_range(0.5, 5.0) = 2.0;
uniform float crease_thickness : hint_range(0.5, 5.0) = 1.1;
// relative depth gap (silhouettes)
uniform float depth_threshold : hint_range(0.0, 1.0) = 0.08;
// creases: the depth slope changes suddenly between both sides of the pixel
uniform float crease_threshold : hint_range(0.0, 1.0) = 0.25;
// lines where the color changes suddenly (0 = off), drawn on the lighter side: flat surfaces
// made of several colors, e.g. the chessboard squares
uniform float color_threshold : hint_range(0.0, 1.0) = 0.0;
uniform float color_thickness : hint_range(0.5, 5.0) = 1.0;
// lines fade out with the distance, like the details in the light fog
uniform float fade_start = 10.0;
uniform float fade_end = 18.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_projection) {
	// OpenGL: depth buffer in [0, 1] -> NDC z in [-1, 1]
	float depth = texture(depth_texture, uv).r * 2.0 - 1.0;
	vec4 view = inv_projection * vec4(uv * 2.0 - 1.0, depth, 1.0);
	return -view.z / view.w;
}

float silhouette(float center, float a, float b, float far_gap) {
	// on a plane 1/depth is linear on screen: its second derivative is ~0 on flat surfaces,
	// even seen almost edge-on (big depth gaps between pixels), and only breaks on silhouettes / creases
	float plane_error = abs(center / a + center / b - 2.0);
	return smoothstep(depth_threshold, depth_threshold * 1.5, far_gap / center) * step(depth_threshold * 0.5, plane_error);
}

void fragment() {
	vec2 pixel = (VIEWPORT_SIZE.y / 600.0) / VIEWPORT_SIZE;
	vec2 bold = pixel * thickness;
	vec2 thin = pixel * crease_thickness;

	float center = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);

	// silhouettes: a neighbour is much farther and not on the same plane (bold lines)
	float left = linear_depth(SCREEN_UV - vec2(bold.x, 0.0), INV_PROJECTION_MATRIX);
	float right = linear_depth(SCREEN_UV + vec2(bold.x, 0.0), INV_PROJECTION_MATRIX);
	float down = linear_depth(SCREEN_UV - vec2(0.0, bold.y), INV_PROJECTION_MATRIX);
	float up = linear_depth(SCREEN_UV + vec2(0.0, bold.y), INV_PROJECTION_MATRIX);
	float edge = max(
		silhouette(center, left, right, max(left, right) - center),
		silhouette(center, down, up, max(down, up) - center));

	// creases: the surface orientation changes (thin lines)
	float crease_x = abs(center / linear_depth(SCREEN_UV - vec2(thin.x, 0.0), INV_PROJECTION_MATRIX)
			+ center / linear_depth(SCREEN_UV + vec2(thin.x, 0.0), INV_PROJECTION_MATRIX) - 2.0);
	float crease_y = abs(center / linear_depth(SCREEN_UV - vec2(0.0, thin.y), INV_PROJECTION_MATRIX)
			+ center / linear_depth(SCREEN_UV + vec2(0.0, thin.y), INV_PROJECTION_MATRIX) - 2.0);
	edge = max(edge, smoothstep(crease_threshold * 0.1, crease_threshold * 0.13, max(crease_x, crease_y)));

	if (color_threshold > 0.0) {
		const vec3 luma_weights = vec3(0.2126, 0.7152, 0.0722);
		float luma = dot(textureLod(screen_texture, SCREEN_UV, 0.0).rgb, luma_weights);
		vec2 side = pixel * color_thickness;
		vec2 sides[4] = vec2[](vec2(side.x, 0.0), vec2(-side.x, 0.0), vec2(0.0, side.y), vec2(0.0, -side.y));
		for (int i = 0; i < 4; i++) {
			float neighbour = dot(textureLod(screen_texture, SCREEN_UV + sides[i], 0.0).rgb, luma_weights);
			edge = max(edge, smoothstep(color_threshold, color_threshold * 1.3, luma - neighbour));
		}
	}

	float fade = 1.0 - smoothstep(fade_start, fade_end, center);
	vec3 shade = textureLod(screen_texture, SCREEN_UV, 0.0).rgb * line_darkness;
	ALBEDO = mix(outline_color.rgb, shade, line_tint);
	ALPHA = edge * fade * outline_color.a;
}

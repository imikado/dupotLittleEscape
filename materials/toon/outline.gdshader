// Cartoon outlines as a screen post-process: a full screen quad attached to the camera
// draws a line where the depth or the surface orientation changes suddenly.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D normal_texture : hint_normal_roughness_texture, filter_nearest, repeat_disable;
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
// angle between surfaces (creases), 1 - cos(angle)
uniform float normal_threshold : hint_range(0.0, 2.0) = 0.6;
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
	float depth = texture(depth_texture, uv).r;
	vec4 view = inv_projection * vec4(uv * 2.0 - 1.0, depth, 1.0);
	return -view.z / view.w;
}

vec3 view_normal(vec2 uv) {
	return texture(normal_texture, uv).xyz * 2.0 - 1.0;
}

void fragment() {
	vec2 pixel = (VIEWPORT_SIZE.y / 600.0) / VIEWPORT_SIZE;
	// by pairs (+/-): straight then diagonal directions, so thick lines stay round
	const float d = 0.7071;
	vec2 directions[8] = vec2[](
		vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0),
		vec2(d, d), vec2(-d, -d), vec2(d, -d), vec2(-d, d));

	float center_depth = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 center_normal = view_normal(SCREEN_UV);

	float depths[8];
	for (int i = 0; i < 8; i++) {
		depths[i] = linear_depth(SCREEN_UV + directions[i] * pixel * thickness, INV_PROJECTION_MATRIX);
	}

	float edge = 0.0;
	for (int i = 0; i < 8; i++) {
		float depth = depths[i];
		// opposite neighbour (directions go by pairs)
		float opposite = depths[i ^ 1];
		// on a plane 1/depth is linear on screen: a surface seen almost edge-on has big depth gaps
		// between pixels but stays planar, only a real silhouette breaks the plane
		float plane_error = abs(center_depth / depth + center_depth / opposite - 2.0);
		// only the far side of a silhouette gets the line, so it stays on the outside of the objects
		float depth_edge = smoothstep(depth_threshold, depth_threshold * 1.5, (depth - center_depth) / center_depth)
				* step(depth_threshold * 0.5, plane_error);
		edge = max(edge, depth_edge);
	}
	// creases: thinner, straight directions only
	for (int i = 0; i < 4; i++) {
		float crease = 1.0 - dot(center_normal, view_normal(SCREEN_UV + directions[i] * pixel * crease_thickness));
		edge = max(edge, smoothstep(normal_threshold, normal_threshold * 1.3, crease));
	}

	if (color_threshold > 0.0) {
		const vec3 luma_weights = vec3(0.2126, 0.7152, 0.0722);
		float luma = dot(textureLod(screen_texture, SCREEN_UV, 0.0).rgb, luma_weights);
		for (int i = 0; i < 4; i++) {
			float neighbour = dot(textureLod(screen_texture, SCREEN_UV + directions[i] * pixel * color_thickness, 0.0).rgb, luma_weights);
			edge = max(edge, smoothstep(color_threshold, color_threshold * 1.3, luma - neighbour));
		}
	}

	float fade = 1.0 - smoothstep(fade_start, fade_end, center_depth);
	vec3 shade = textureLod(screen_texture, SCREEN_UV, 0.0).rgb * line_darkness;
	ALBEDO = mix(outline_color.rgb, shade, line_tint);
	ALPHA = edge * fade * outline_color.a;
}

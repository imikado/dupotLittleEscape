// Soft contact shadow under a furniture (common/contactShadows.gd): a quad on the floor, scaled to
// the furniture footprint plus the blur on each side, darker under the furniture.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

// dark purple of the cartoon palette, softer than black
uniform vec4 color : source_color = vec4(0.16, 0.13, 0.26, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.3;
// width of the soft edge around the footprint, in meters
uniform float blur = 0.2;
// room interior (min x, min z, max x, max z): nothing drawn under the walls and in the next room
uniform vec4 clip_rect = vec4(-10000.0, -10000.0, 10000.0, 10000.0);

varying vec2 size;
varying vec3 world_position;

void vertex() {
	// the quad is 1x1, its scale is the shadow size
	size = vec2(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[2].xyz));
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// distance to the footprint rectangle in meters (negative inside)
	vec2 d = abs(UV - 0.5) * size - (size * 0.5 - blur);
	float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
	float shadow = 1.0 - smoothstep(-blur * 0.5, blur, dist);
	float inside = step(clip_rect.x, world_position.x) * step(clip_rect.y, world_position.z)
			* step(world_position.x, clip_rect.z) * step(world_position.z, clip_rect.w);
	ALBEDO = color.rgb;
	ALPHA = shadow * strength * inside;
}

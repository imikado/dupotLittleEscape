// Paintings in the frames, drawn with flat cartoon shapes.
// style: 0 mountains and sun, 1 colored shapes, 2 sea and sailing boat
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;

uniform int style = 0;
// width / height of the painting, so the shapes stay round
uniform float aspect = 1.0;

float circle(vec2 uv, vec2 center, float radius) {
	return 1.0 - smoothstep(radius - 0.006, radius, length(uv - center));
}

float box(vec2 uv, vec2 from, vec2 to) {
	return step(from.x, uv.x) * step(from.y, uv.y) * step(uv.x, to.x) * step(uv.y, to.y);
}

// above the line from a to b (uv y goes down), between a.x and b.x
float triangle(vec2 uv, vec2 left, vec2 top, vec2 right) {
	float l = step((uv.x - left.x) * (top.y - left.y) / (top.x - left.x) + left.y, uv.y) * step(left.x, uv.x) * step(uv.x, top.x);
	float r = step((uv.x - top.x) * (right.y - top.y) / (right.x - top.x) + top.y, uv.y) * step(top.x, uv.x) * step(uv.x, right.x);
	return max(l, r);
}

void fragment() {
	vec2 uv = vec2(UV.x * aspect, UV.y);
	vec3 color;
	if (style == 0) {
		color = mix(vec3(0.99, 0.80, 0.55), vec3(1.0, 0.93, 0.78), UV.y);
		color = mix(color, vec3(0.98, 0.45, 0.35), circle(uv, vec2(aspect * 0.7, 0.32), 0.14));
		color = mix(color, vec3(0.55, 0.45, 0.80), triangle(UV, vec2(-0.2, 1.0), vec2(0.35, 0.35), vec2(0.9, 1.0)));
		color = mix(color, vec3(1.0, 0.98, 0.95), triangle(UV, vec2(0.23, 0.5), vec2(0.35, 0.35), vec2(0.47, 0.5)));
		color = mix(color, vec3(0.40, 0.66, 0.62), triangle(UV, vec2(0.3, 1.0), vec2(0.75, 0.55), vec2(1.2, 1.0)));
	} else if (style == 1) {
		color = vec3(0.98, 0.95, 0.88);
		color = mix(color, vec3(0.38, 0.78, 0.86), box(UV, vec2(0.1, 0.12), vec2(0.55, 0.5)));
		color = mix(color, vec3(1.0, 0.80, 0.18), circle(uv, vec2(aspect * 0.66, 0.62), 0.22));
		color = mix(color, vec3(0.96, 0.43, 0.40), box(UV, vec2(0.25, 0.68), vec2(0.5, 0.9)));
		color = mix(color, vec3(0.14, 0.15, 0.24), box(UV, vec2(0.62, 0.1), vec2(0.88, 0.16)));
	} else {
		color = mix(vec3(0.55, 0.78, 0.98), vec3(0.95, 0.90, 0.85), UV.y * 1.6);
		color = mix(color, vec3(1.0, 0.86, 0.35), circle(uv, vec2(aspect * 0.25, 0.25), 0.1));
		color = mix(color, vec3(0.25, 0.52, 0.85), step(0.62 + 0.015 * sin(UV.x * 30.0), UV.y));
		color = mix(color, vec3(0.98, 0.95, 0.88), triangle(UV, vec2(0.5, 0.58), vec2(0.61, 0.22), vec2(0.62, 0.58)));
		color = mix(color, vec3(0.96, 0.43, 0.40), triangle(UV, vec2(0.64, 0.58), vec2(0.65, 0.3), vec2(0.78, 0.58)));
		color = mix(color, vec3(0.78, 0.49, 0.30), box(UV, vec2(0.45, 0.6), vec2(0.8, 0.68)) * step(UV.x - 0.45, (UV.y - 0.6) * 1.2 + 0.25));
	}
	ALBEDO = color;
}

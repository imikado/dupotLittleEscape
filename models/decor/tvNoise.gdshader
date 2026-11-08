// TV screen without signal: the displayed picture with scanlines, a rolling band and a light
// grain, like an old TV looking for a channel.
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;

uniform sampler2D screen_texture : source_color, filter_nearest;
uniform float scanlines : hint_range(0.0, 1.0) = 0.12;
uniform float grain : hint_range(0.0, 1.0) = 0.12;
uniform float band : hint_range(0.0, 1.0) = 0.1;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	// small horizontal jitter of some lines
	float jitter = step(0.97, hash(vec2(floor(uv.y * 60.0), floor(TIME * 12.0))));
	uv.x += jitter * 0.01 * (hash(vec2(TIME, uv.y)) - 0.5);
	vec3 color = texture(screen_texture, uv).rgb;
	color *= 1.0 - scanlines * step(0.5, fract(uv.y * 60.0));
	float roll = fract(TIME * 0.15);
	color += band * (1.0 - smoothstep(0.0, 0.08, abs(uv.y - roll)));
	color += grain * (hash(floor(uv * vec2(160.0, 90.0)) + floor(TIME * 20.0)) - 0.5);
	// flicker
	color *= 0.96 + 0.04 * sin(TIME * 40.0);
	ALBEDO = clamp(color, 0.0, 1.0);
}

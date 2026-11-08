// Steam on the bathroom mirror (hot water): a misty layer that rises from the bottom,
// amount animated by models/bathroom/mirror.gd.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

uniform vec4 color : source_color = vec4(0.90, 0.94, 1.0, 1.0);
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float opacity : hint_range(0.0, 1.0) = 0.7;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float n = noise(UV * vec2(5.0, 8.0) + vec2(0.0, TIME * 0.08)) * 0.6 + noise(UV * vec2(13.0, 21.0)) * 0.4;
	// grows from the bottom of the mirror (UV.y = 1), with a wavy front
	float rise = smoothstep(0.0, 0.25, amount * 1.3 - (1.0 - UV.y) + (n - 0.5) * 0.15);
	float edge = smoothstep(0.0, 0.08, UV.x) * smoothstep(1.0, 0.92, UV.x) * smoothstep(0.0, 0.06, UV.y) * smoothstep(1.0, 0.94, UV.y);
	ALBEDO = color.rgb;
	ALPHA = rise * edge * (0.55 + 0.45 * n) * opacity * min(amount * 2.0, 1.0);
}

// Water running from the tap: light blue, bright stripes going down.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

uniform vec4 color : source_color = vec4(0.4, 0.72, 1.0, 1.0);
uniform vec4 highlight : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float speed = 3.0;

void fragment() {
	// UV.y goes down the cylinder: the pattern moves down
	float stripe = step(0.7, fract(UV.y * 5.0 - TIME * speed + sin(UV.x * 6.2832) * 0.15));
	ALBEDO = mix(color.rgb, highlight.rgb, stripe * 0.8);
	ALPHA = 0.9;
}

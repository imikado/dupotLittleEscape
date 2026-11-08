// Clue written with a finger on the steamy mirror: shows up as the steam comes.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(0.98, 0.97, 0.94, 1.0);
uniform float amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = amount;
}

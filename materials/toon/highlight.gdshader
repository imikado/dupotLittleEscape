// Object the player is looking at: drawn again over its toon material (material_overlay),
// a warm glow that pulses gently, stronger on the silhouette. Works in Forward+ and Compatibility.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

uniform vec4 highlight_color : source_color = vec4(1.0, 0.9, 0.5, 1.0);
// glow on the whole object
uniform float strength : hint_range(0.0, 1.0) = 0.24;
// extra glow on the faces seen edge-on (silhouette)
uniform float rim_strength : hint_range(0.0, 1.0) = 0.5;
uniform float pulse_speed = 4.0;
// 0 = steady, 1 = fades out completely at the bottom of the pulse
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	// per face normal, like the toon shader (the imported normals are smoothed)
	vec3 face_normal = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	float facing = abs(dot(face_normal, VIEW));
	float rim = pow(1.0 - facing, 2.0);
	float pulse = 1.0 - pulse_amount * (0.5 + 0.5 * sin(TIME * pulse_speed));
	ALBEDO = highlight_color.rgb;
	ALPHA = clamp((strength + rim * rim_strength) * pulse, 0.0, 1.0);
}

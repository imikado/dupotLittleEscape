// Item already used (key that unlocked its door): greyed and faded in the inventory.
shader_type canvas_item;

uniform float fade : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	float luma = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
	COLOR = vec4(vec3(luma), color.a * fade);
}

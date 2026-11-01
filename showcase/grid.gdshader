shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
void fragment() {
	vec2 coord = UV * 24.0;
	vec2 width = max(fwidth(coord), vec2(0.0001));
	vec2 lines = abs(fract(coord - 0.5) - 0.5) / width;
	float ink = 1.0 - min(min(lines.x, lines.y), 1.0);
	ALBEDO = mix(vec3(0.035, 0.065, 0.095), vec3(0.12, 0.23, 0.29), ink * 0.65);
}

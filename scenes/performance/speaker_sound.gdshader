shader_type spatial;
render_mode unshaded, blend_add;

uniform vec4 color : source_color;
uniform float radius = 0.0;
uniform float thickness = 0.01;

void fragment() {
	float _radius = 0.5 * radius - thickness;
	float opacity = max(0.0, 1.0 - radius);
	
	vec2 center = vec2(0.5, 0.5);
	vec2 local_uv = UV - center;
	float a = atan(local_uv.y, local_uv.x);
	float r = distance(center, UV);
	float d = abs(_radius - r);
	float circle = mix(1.0, 0.0, smoothstep(0.5 * thickness, 1.5 * thickness, d));
	
	ALBEDO = color.rgb * circle * opacity;
}

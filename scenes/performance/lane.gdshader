shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never;

uniform vec4 color : source_color;
uniform float brightness = 0.5;

void fragment() {
	float gradient = UV.x;
	// An inverted parabola with the peak at (0.5, 1.0)
	gradient = -4.0 * gradient * gradient + 4.0 * gradient;
	gradient *= UV.y;
	ALBEDO = brightness * color.rgb * gradient;
	
}

shader_type spatial;
render_mode blend_add, cull_front, unshaded, depth_draw_never;

uniform sampler2D noise_texture : source_color;
uniform sampler2D gradient_texture : source_color;
uniform vec4 color : source_color;

varying vec2 scrolling_uv;

void vertex() {
	scrolling_uv = UV + TIME * vec2(0.0, -0.1);
}


void fragment() {
	vec3 cl = texture(noise_texture, scrolling_uv).rgb * color.rgb * texture(gradient_texture, vec2(UV.y,0)).rgb;
	ALBEDO = cl;

}
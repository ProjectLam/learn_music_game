shader_type spatial;
render_mode blend_add, cull_front, unshaded;

uniform sampler2D noise_texture : hint_default_white;
uniform vec4 color : source_color;

varying vec2 scrolling_uv;

void vertex() {
	scrolling_uv = UV + TIME * vec2(0.0, -0.1);
}

void fragment() {
	ALBEDO = texture(noise_texture, scrolling_uv).rgb * UV.y;
	ALBEDO *= ALBEDO * 0.3;
	ALBEDO *= color.rgb;
}

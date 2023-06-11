shader_type canvas_item;

global uniform float panel_blur;
uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap;



void fragment() {
	vec4 tex_color = textureLod(screen_texture, SCREEN_UV, panel_blur);
	COLOR.xyz = mix(tex_color.xyz, COLOR.xyz, COLOR.w);//vec4(tex_color.xyz,0.3);
	COLOR.w = COLOR.w > 0.001 ? 1.0 : 0.0;
}

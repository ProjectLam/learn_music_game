shader_type canvas_item;

uniform float blur = 0.0;



vec4 texture_blurred(sampler2D tex, vec2 uv, float p_blur) {
	vec4 col = vec4(0.0);
	
	return col;
}

void fragment() {
	COLOR = texture_blurred(TEXTURE,UV, blur);
}

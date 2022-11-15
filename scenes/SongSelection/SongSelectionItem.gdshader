shader_type canvas_item;

uniform bool indicate = false;
uniform vec2 size;
uniform vec2 indicating_point = vec2(0.5);
uniform float indicating_power: hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float radius_base: hint_range(0.0, 1.0, 0.1) = 0.5;

void fragment() {
	if (indicate) {
		float ratio = 1.0;
		
		if (size.x > size.y) {
			ratio = size.x / size.y;
		} else if (size.x < size.y) {
			ratio = size.y / size.x;
		}
		
		float dx = UV.x - indicating_point.x;
		float dy = UV.y - indicating_point.y;
		dx *= ratio;
		
		float r = radius_base + sqrt(pow(dx, 2.0) + pow(dy, 2.0));
		r *= indicating_power;
		
//		r *= smoothstep(0.3, 0.6, fract(sin(TIME*3.0)));
		
		COLOR.a = r;
	}
}

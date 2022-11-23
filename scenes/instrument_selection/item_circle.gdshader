shader_type canvas_item;

uniform float radius: hint_range(0., 1.) = 1;
uniform bool animate = false;
uniform float square_scale: hint_range(0., 1.) = 0.1;
uniform vec4 albedo: source_color;

uniform bool indicate = false;
uniform vec2 size;
uniform vec2 lighting_point = vec2(0.5);
uniform float indicating_power: hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float radius_base: hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float static_power: hint_range(0.0, 1.0, 0.1) = 0.5;

void fragment() {
	COLOR = albedo;
	
	if (indicate) {
		float ratio = 1.0;

		if (size.x > size.y) {
			ratio = size.x / size.y;
		} else if (size.x < size.y) {
			ratio = size.y / size.x;
		}

		float dx = UV.x - lighting_point.x;
		float dy = UV.y - lighting_point.y;
		dx *= ratio;

		float r = radius_base + sqrt(pow(dx, 2.0) + pow(dy, 2.0));
		r *= indicating_power;

		COLOR.a = r;
	} else {
		float ratio = 1.0;
		vec2 csize = vec2(0.9);
		vec2 clp = vec2(0.9);
		
		if (csize.x > csize.y) {
			ratio = csize.x / csize.y;
		} else if (csize.x < csize.y) {
			ratio = csize.y / csize.x;
		}
		
		float dx = UV.x - clp.x;
		float dy = UV.y - clp.y;
		dx *= ratio;
		
		float r = sqrt(pow(dx, 2.0) + pow(dy, 2.0));
		r *= 1.0 - static_power;
		
		COLOR.a = r;
	}
	
    float sc = square_scale + square_scale/2.;
    float r = square_scale + (1. - radius) * (square_scale/2.);
    
    float scax = 1. - square_scale;
    
    float dx;
    float dy;
    float d;
    float a;
    
    if (UV.x < square_scale && UV.y > scax) {
        dx = square_scale - UV.x;
        dy = scax - UV.y;
        d = sqrt(pow(dx, 2.) + pow(dy, 2.));
        a = asin(d);
        
        if (a > r) {
            if (!animate) {
                COLOR.a = 0.;
            } else if (a > sc * sin(3.14 * fract(TIME))) {
                COLOR.a = 0.;
            }
        }
    }
    
    if (UV.x < square_scale && UV.y < square_scale) {
        dx = square_scale - UV.x;
        dy = square_scale - UV.y;
        d = sqrt(pow(dx, 2.) + pow(dy, 2.));
        a = asin(d);
        
        if (a > r) {
            if (!animate) {
                COLOR.a = 0.;
            } else if (a > sc * sin(3.14 * fract(TIME))) {
                COLOR.a = 0.;
            }
        }
    }
    
    if (UV.x > scax && UV.y < square_scale) {
        dx = scax - UV.x;
        dy = square_scale - UV.y;
        d = sqrt(pow(dx, 2.) + pow(dy, 2.));
        a = asin(d);
        
        if (a > r) {
            if (!animate) {
                COLOR.a = 0.;
            } else if (a > sc * sin(3.14 * fract(TIME))) {
                COLOR.a = 0.;
            }
        }
    }

    if (UV.x > scax && UV.y > scax) {
        dx = scax - UV.x;
        dy = scax - UV.y;
        d = sqrt(pow(dx, 2.) + pow(dy, 2.));
        a = asin(d);
        
        if (a > r) {
            if (!animate) {
                COLOR.a = 0.;
            } else if (a > sc * sin(3.14 * fract(TIME))) {
                COLOR.a = 0.;
            }
        }
    }
}
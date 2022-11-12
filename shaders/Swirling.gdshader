/*
 * Meowing Cat's Whirling Spawn Shader
 * Copyright (C) 2022, Oğuzhan Eroğlu (https://github.com/rohanrhu)
 * Licensed under MIT.
 */

shader_type spatial;
render_mode depth_draw_always, diffuse_toon;

uniform float power: hint_range(1.0, 10.0) = 1.0;
uniform float deconstruction: hint_range(0.0, 1.0) = 0.0;
uniform float radius: hint_range(0.0, 20.0) = 1.0;
uniform sampler2D albedo: source_color;
uniform float swirling: hint_range(-3.1415, 3.1415) = 0.0;
uniform float opacity: hint_range(0.0, 1.0) = 1.0;

varying mat4 CAMERA;

void vertex() {
	float a2d = atan(VERTEX.x, VERTEX.z);
	float r = sqrt(pow(VERTEX.x, 2) + pow(VERTEX.z, 2)) * radius;
	float a = a2d + swirling;
	
	float p = deconstruction * VERTEX.y;
	a *= (VERTEX.y * power * p) / (1.0 - p);
	
	VERTEX.x += sin(a) * r;
	VERTEX.z += cos(a) * r;;
}

void fragment() {
	vec4 txt = texture(albedo, UV);
	ALBEDO.rgb = txt.rgb;
	ALPHA = opacity;
}

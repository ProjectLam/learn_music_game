shader_type canvas_item;
vec2 uv_curve(vec2 textCoord){
	textCoord = (textCoord - 0.5) * 2.0;
	textCoord.x *= 1.0 - pow(abs(textCoord.y)*-0.5, 2.0);
	textCoord.y *= 1.0 - pow(abs(textCoord.x)/10.0, 2.0);
// Play with the values above, to change the perspective.
//Do keep 1.0-, if you want the song buttons display to be to the left.Else, 1.0+
	textCoord = (textCoord*0.5) + 0.5;
	return textCoord;
}
void fragment(){
	vec4 screenColor = texture(SCREEN_TEXTURE, uv_curve(SCREEN_UV));
	COLOR = screenColor;
}

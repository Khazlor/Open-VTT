shader_type canvas_item;
render_mode blend_mul, light_only;

void light(){
	float a = LIGHT_COLOR.r;
    LIGHT = texture(TEXTURE, SCREEN_UV);
	LIGHT.a = a;
}
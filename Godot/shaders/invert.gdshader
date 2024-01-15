shader_type canvas_item;
render_mode blend_mix,light_only;

void light(){
	if (LIGHT.a == 0.0){
		LIGHT.a = 1.0;
	}
}


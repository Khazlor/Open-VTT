shader_type canvas_item;

uniform vec2 size = vec2(700, 700); 
uniform float line_width : hint_range(0, 1) = 0.1;
uniform vec2 offset = vec2(0.0, 0.0);
uniform float grid_size = 70.0;

void fragment() {
	vec2 r = mod(UV * size, vec2(grid_size));
	vec2 lines = smoothstep(0.98, 1, r / vec2(grid_size));
	float alpha = dot(lines, vec2(1.0, 1.0));
	COLOR.a = alpha;
}
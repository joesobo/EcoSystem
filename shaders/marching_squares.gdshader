shader_type canvas_item;

uniform sampler2D state_texture;
uniform int x_size;
uniform int y_size;
uniform vec2 offset;

float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    // TODO: convert frag coordinate into texture coordinate to look up color
	vec2 state_pos = floor(FRAGCOORD.xy / vec2(32.0, 32.0));
	vec2 normalized_state_pos = floor(state_pos / vec2(float(x_size), float(y_size)));
	
	float state = texture(state_texture, normalized_state_pos).r;
	
    vec4 color;
	if (state == 2.0 / 255.0) {
		color = vec4(0.0, 0.0, 0.0, 1.0); // Black for state 2
	} else if (state == 1.0 / 255.0) {
		color = vec4(1.0, 1.0, 1.0, 1.0); // White for state 1
	} else {
		color = vec4(0.0, 0.0, 0.0, 1.0); // Transparent for state 0
	}
    
    COLOR = color;
}

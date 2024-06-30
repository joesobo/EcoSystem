shader_type canvas_item;

uniform sampler2DArray texture_array: filter_nearest;
uniform vec2 offset = vec2(0.0, 0.0);
uniform float texture_size = 16.0;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy + offset;
}

void fragment() {
	float state_index = COLOR.r * 255.0;

	vec2 texture_coord = fract(world_position / texture_size);

	COLOR = texture(texture_array, vec3(texture_coord, state_index));
}

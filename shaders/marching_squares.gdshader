shader_type canvas_item;

uniform sampler2D state_texture;
uniform sampler2DArray texture_array;
uniform vec2 offset;
uniform vec2 world_size = vec2(41, 24);
uniform float voxel_size = 16.0;
uniform float texture_size = 16.0;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy + offset;
}

void fragment() {
	ivec2 tex_coord = ivec2(floor(world_position / voxel_size));

	float voxel_state = texture(state_texture, (vec2(tex_coord) + 0.5) / (world_size)).r * 255.0;

	vec2 texture_coord = mod(world_position, texture_size) / texture_size;

	vec4 tex_color = texture(texture_array, vec3(texture_coord, voxel_state));

	if (voxel_state == 0.0) {
		COLOR = vec4(0.0);
	} else {
		COLOR = tex_color;
	}
}

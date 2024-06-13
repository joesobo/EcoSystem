shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_thickness : hint_range(0.0, 5.0) = 0.0;

void fragment() {
	vec2 texel_size = outline_thickness * vec2(1.0) / vec2(textureSize(TEXTURE, 0));
	vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE;
	vec4 color = texture(TEXTURE, UV);
	vec4 outline = vec4(outline_color.rgb, 0.0);

	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			if (x != 0 || y != 0) {
				vec4 neighbor = texture(TEXTURE, UV + vec2(float(x), float(y)) * texel_size);

				if (neighbor.a == 0.0) {
					outline.a = outline_color.a;
				}
			}
		}
	}

	COLOR = mix(color, outline, outline.a);
}

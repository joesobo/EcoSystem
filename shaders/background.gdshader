// Credit to Nick Brooking - https://www.youtube.com/watch?v=NwZLunEVJBM

shader_type canvas_item;

uniform vec2 cutoffs[10];
uniform float offset_multipliers[10];

void fragment () {
	float sum_slices = 0.0;
	float running_b = 0.0;
	float y = 1.0 - UV.y * 2.0;

	for (int i = 0; i < 10; i++) {
		if (y > sum_slices) {
			sum_slices += cutoffs[i][0] + sin(TIME * offset_multipliers[i]) * cutoffs[i][1];
			running_b += cutoffs[i][1] + sin(TIME * offset_multipliers[i]) * cutoffs[i][1];
		} else {
			break;
		}
	}

	if (y + running_b > UV.x) {
		COLOR.a = 0.0;
	} else {
		COLOR.a = 1.0;
	}
}

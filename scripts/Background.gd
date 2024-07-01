extends Node

@export var slice_count = 20.0
@export var start_color = Color(0.5, 0.5, 0.5)
@export var end_color = Color(0.1, 0.1, 0.1)

func _ready():
	var slice = get_child(0)

	for i in range(slice_count):
		var new_slice = slice.duplicate()
		add_child(new_slice)
		setup_shader(new_slice)

		new_slice.scale = Vector2(1920, 1080)

		var pos = i * 40 - 180
		new_slice.position = Vector2(pos, pos)
		new_slice.move_to_front()

		new_slice.modulate = start_color.lerp(end_color, i / slice_count)

func setup_shader(slice):
	var shader_material = ShaderMaterial.new()
	shader_material.shader = slice.material.shader

	var cutoffs = PackedVector2Array()
	var offset_multipliers = PackedFloat32Array()

	for i in range(10):
		var random_x = randf_range(0.05, 0.2)
		var random_y = randf_range(0.05, 0.2)
		cutoffs.append(Vector2(random_x, random_y))

		var random_multiplier = randf_range(0.01, 0.06)
		offset_multipliers.append(random_multiplier)

	shader_material.set_shader_parameter("cutoffs", cutoffs)
	shader_material.set_shader_parameter("offset_multipliers", offset_multipliers)

	slice.material = shader_material

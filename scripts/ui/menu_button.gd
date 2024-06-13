extends Button

var current_material

func _ready():
	current_material = material as ShaderMaterial
	current_material.set_shader_parameter("color", Color(1,1,1,0))

	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

func _on_mouse_entered():
	current_material.set_shader_parameter("color", Color(1,1,1,1))

func _on_mouse_exited():
	current_material.set_shader_parameter("color", Color(1,1,1,0))

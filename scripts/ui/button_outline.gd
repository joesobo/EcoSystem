extends Button

@export var default_texture: Texture
@export var active_texture: Texture

var current_material

func _ready():
	var unique_material = material.duplicate() as ShaderMaterial
	current_material = unique_material
	material = unique_material
	current_material.set_shader_parameter("color", Color(1,1,1,0))

	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

func _on_mouse_entered():
	current_material.set_shader_parameter("color", Color(1,1,1,1))

func _on_mouse_exited():
	current_material.set_shader_parameter("color", Color(1,1,1,0))

func set_active():
	self.icon = active_texture

func set_default():
	self.icon = default_texture

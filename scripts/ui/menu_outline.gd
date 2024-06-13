extends Control

var current_material
@onready var root_menu = $".."

func _ready():
	var unique_material = material.duplicate() as ShaderMaterial
	current_material = unique_material
	material = unique_material
	current_material.set_shader_parameter("color", Color(1,1,1,0))

	UISingleton.connect("set_focus_menu", Callable(self, "set_focus"))
	UISingleton.connect("clear_focus_menu", Callable(self, "clear_focus"))

func set_focus(key):
	if root_menu.menu.key == key:
		current_material.set_shader_parameter("color", Color(1,1,1,1))

func clear_focus(key):
	if root_menu.menu.key == key:
		current_material.set_shader_parameter("color", Color(1,1,1,0))

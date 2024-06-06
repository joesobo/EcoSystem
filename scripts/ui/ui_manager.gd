extends Node

var active_menu = null

@export var storage_menu_scene = preload("res://scenes/storage_menu.tscn")
@export var breeding_menu_scene = preload("res://scenes/breeding_menu.tscn")

var menus = {
	UISingleton.MenuType.Storage: {
		"scene": storage_menu_scene,
		"instances": {}
	},
	UISingleton.MenuType.Breeding: {
		"scene": breeding_menu_scene,
		"instances": {}
	}
}

func _input(event):
	if event.is_action_pressed("toggle_breeding"):
		toggle_menu(UISingleton.MenuType.Breeding, 0)

func toggle_menu(menu_name: UISingleton.MenuType, index: int):
	var menu_info = menus[menu_name]
	if menu_info["instances"].has(index):
		close_menu(menu_name, index)
	else:
		menu_info["instances"][index] = open_menu(menu_info["scene"])

func open_menu(menu_scene):
	var menu_instance = menu_scene.instantiate()
	add_child(menu_instance)
	menu_instance.global_position = get_viewport().get_mouse_position()
	menu_instance.connect("menu_activated", Callable(self, "_on_menu_activated"))
	_on_menu_activated(menu_instance)
	return menu_instance

func close_menu(menu_name: UISingleton.MenuType, index: int):
	var menu_info = menus[menu_name]
	if menu_info["instances"].has(index):
		menu_info["instances"][index].queue_free()
		menu_info["instances"].erase(index)

func _on_menu_activated(menu):
	active_menu = menu

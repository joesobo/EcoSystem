extends Node

var open_menus = {}
var active_menu = null

@export var storage_menu_scene = preload("res://scenes/storage_menu.tscn")
@export var breeding_menu_scene = preload("res://scenes/breeding_menu.tscn")

var menu_types = {
	UISingleton.MenuType.Breeding: breeding_menu_scene,
	UISingleton.MenuType.Storage: storage_menu_scene,
}

func _input(event):
	if event.is_action_pressed("toggle_breeding"):
		toggle_menu(UISingleton.MenuType.Breeding, 0)
	if active_menu && event.is_action_pressed("close"):
		close_active_menu()

func get_menu_key(menu_name: UISingleton.MenuType, index: int) -> String:
	return str(menu_name) + "_" + str(index)

func toggle_menu(menu_name: UISingleton.MenuType, index: int):
	var key = get_menu_key(menu_name, index)

	if open_menus.has(key):
		close_menu(menu_name, index)
	else:
		open_menus[key] = open_menu(menu_name, index)

func open_menu(menu_name: UISingleton.MenuType, index: int):
	var key = get_menu_key(menu_name, index)

	var menu_instance = menu_types[menu_name].instantiate()
	menu_instance.index = index
	add_child(menu_instance)
	open_menus[key] = menu_instance
	menu_instance.global_position = get_viewport().get_mouse_position()
	active_menu = menu_instance

	menu_instance.connect("menu_closed", Callable(self, "close_menu"))

	return menu_instance

func close_menu(menu_name: UISingleton.MenuType, index: int):
	var key = get_menu_key(menu_name, index)

	if open_menus.has(key):
		open_menus[key].queue_free()
		open_menus.erase(key)

	next_active_menu()

func close_active_menu():
	if active_menu:
		# find in open_menus where active_menu is and remove it
		for key in open_menus.keys():
			if open_menus[key] == active_menu:
				open_menus.erase(key)
				break

		active_menu.queue_free()
		active_menu = null

		next_active_menu()

func next_active_menu():
	if open_menus.size() > 0:
		var keys_array = open_menus.keys()
		var last_key = keys_array[keys_array.size() - 1]

		active_menu = open_menus[last_key]
	else:
		active_menu = null

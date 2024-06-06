extends Node

@export var storage_menu_scene = preload("res://scenes/storage_menu.tscn")
@export var breeding_menu_scene = preload("res://scenes/breeding_menu.tscn")

var menu_types = {
	UISingleton.MenuType.Breeding: breeding_menu_scene,
	UISingleton.MenuType.Storage: storage_menu_scene,
}

func _input(event):
	if event.is_action_pressed("toggle_breeding"):
		toggle_menu(UISingleton.MenuType.Breeding, 0)
	elif UISingleton.get_active_menu() && event.is_action_pressed("close"):
		var active_menu = UISingleton.get_active_menu()
		close_menu(active_menu.key)

func toggle_menu(menu_name: UISingleton.MenuType, index: int):
	var key = UISingleton.get_menu_key(menu_name, index)
	var menu = UISingleton.get_menu_by_key(key)

	if menu and menu.opened:
		close_menu(key)
	elif menu and !menu.opened:
		open_menu(key)
	else:
		new_menu(menu_name, index)

func new_menu(menu_name: UISingleton.MenuType, index: int):
	var key = UISingleton.get_menu_key(menu_name, index)

	var menu_instance = menu_types[menu_name].instantiate()

	menu_instance.index = index
	menu_instance.global_position = get_viewport().get_mouse_position()
	add_child(menu_instance)
	menu_instance.connect("menu_closed", Callable(self, "close_menu"))

	UISingleton.create_menu(key, menu_instance)

func open_menu(key: String):
	var menu = UISingleton.get_menu_by_key(key)

	menu.opened = true
	UISingleton.clear_active_menu()
	menu.focused = true
	menu.instance.show()

func close_menu(key: String):
	var menu = UISingleton.get_menu_by_key(key)

	menu.opened = false
	menu.focused = false
	menu.instance.hide()

	UISingleton.next_active_menu(key)


extends Node

signal set_hovered_menu(menu_key)
signal clear_hovered_menu(menu_key)

enum MenuType {
	Storage,
	Breeding,
	Hotbar,
	Inventory
}

var menus: Array[Menu] = []
var storage_map = {}
var follow_mouse_object: Panel

func get_menu_key(menu_name: MenuType, index: int) -> String:
	return str(menu_name) + "_" + str(index)

func get_menu_by_key(key: String):
	for menu in menus:
		if menu.key == key:
			return menu
	return null

func create_menu(key: String, instance: Node) -> Menu:
	var new_menu = Menu.new(
		key,
		instance.position,
		[],
		true,
		false,
		instance
	)

	menus.append(new_menu)

	return new_menu

func update_menu(key):
	var menu = get_menu_by_key(key)

	if menu.hovered:
		emit_signal("set_hovered_menu", key)
	else:
		emit_signal("clear_hovered_menu", key)

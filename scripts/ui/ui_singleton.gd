extends Node

enum MenuType {
	Storage,
	Breeding
}

var menus: Array[Menu] = []

func get_menu_key(menu_name: MenuType, index: int) -> String:
	return str(menu_name) + "_" + str(index)

func get_active_menu():
	for menu in menus:
		if menu.focused:
			return menu
	return null

func get_menu_by_key(key: String):
	for menu in menus:
		if menu.key == key:
			return menu
	return null

func create_menu(key: String, instance: Node):
	var new_menu = Menu.new(key, instance.position, 0, [], true, true, instance)

	for menu in menus:
		if menu.focused:
			menu.focused = false

	menus.append(new_menu)

func next_active_menu(key: String):
	var index = -1

	for i in range(menus.size()):
		if menus[i].key == key:
			index = i
			break

	if index != -1:
		menus[index].focused = false

		for i in range(index - 1, -1, -1):  # Counts backwards from index - 1 to 0
			if menus[i].opened:
				menus[i].focused = true
				break

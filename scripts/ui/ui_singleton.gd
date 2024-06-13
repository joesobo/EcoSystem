extends Node

signal set_focus_menu(menu_key)
signal clear_focus_menu(menu_key)

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

func create_menu(key: String, instance: Node) -> Menu:
	var new_menu = Menu.new(
		key,
		instance.position,
		[
			ItemDefinition.items[0].clone(),
			ItemDefinition.items[0].clone(),
			ItemDefinition.items[0].clone(),
			ItemDefinition.items[1].clone(),
			ItemDefinition.items[0].clone()
		],
		true,
		false,
		instance
	)

	menus.append(new_menu)

	return new_menu

func set_focused_menu(key):
	for menu in menus:
		if menu.key == key:
			emit_signal("set_focus_menu", key)
			menu.focused = true
		else:
			emit_signal("clear_focus_menu", menu.key)
			menu.focused = false

func clear_active_menu():
	for menu in menus:
		if menu.focused:
			menu.focused = false

func next_active_menu(key: String):
	var index = -1

	for i in range(menus.size()):
		if menus[i].key == key:
			index = i
			break

	if index != -1:
		var found_previous = false
		for i in range(index - 1, -1, -1):  # Counts backwards from index - 1 to 0
			if menus[i].opened:
				menus[i].focused = true
				found_previous = true
				break

		if !found_previous:
			for menu in menus:
				if menu.opened:
					menu.focused = true
					break

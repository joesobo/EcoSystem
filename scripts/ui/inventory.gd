extends Control

@onready var hotbar = %Hotbar
@onready var extended_inventory = %Extended
@onready var slot_outline = %"Slot Outline"

var extended: bool = false
var focus_slot: int = 1
var start_position = Vector2(-95, -24)
var horizontal_increment = 19
var vertical_increment = -40

var key_to_slot = {
	KEY_1: 1,
	KEY_2: 2,
	KEY_3: 3,
	KEY_4: 4,
	KEY_5: 5,
	KEY_6: 6,
	KEY_7: 7,
	KEY_8: 8,
	KEY_9: 9,
	KEY_0: 0
}

func _ready():
	var hotbar_key = UISingleton.get_menu_key(UISingleton.MenuType.Hotbar, 0)
	var hotbar_menu = UISingleton.create_menu(hotbar_key, hotbar)
	hotbar.set_menu(hotbar_menu)

	var inventory_key = UISingleton.get_menu_key(UISingleton.MenuType.Inventory, 0)
	var inventory_menu = UISingleton.create_menu(inventory_key, extended_inventory)
	extended_inventory.set_menu(inventory_menu)

	hotbar.connect('update_slot', Callable(self, 'duplicate_slot_to_extended_inventory'))
	extended_inventory.connect('update_slot', Callable(self, 'duplicate_slot_to_hotbar'))

func _input(event):
	if event.is_action_pressed("inventory"):
		toggle_extend_inventory()

	if event is InputEventKey and event.pressed:
		if event.keycode in key_to_slot:
			set_focus_slot(key_to_slot[event.keycode])

func toggle_extend_inventory():
	extended = !extended

	if extended:
		extended_inventory.show()
		hotbar.hide()
	else:
		extended_inventory.hide()
		hotbar.show()

	move_outline_to_slot(focus_slot)

func set_focus_slot(slot: int):
	focus_slot = slot
	move_outline_to_slot(slot)

func move_outline_to_slot(slot: int):
	var new_position = Vector2()
	if slot == 0:
		new_position = start_position + Vector2(horizontal_increment * 9, 0)
	else:
		new_position = start_position + Vector2(horizontal_increment * (slot - 1), 0)

	if extended:
		new_position.y += vertical_increment
	else:
		new_position.y = start_position.y

	slot_outline.position = new_position

func duplicate_slot_to_extended_inventory(slot_index, item):
	print('duplicating slot ', slot_index)
	extended_inventory.set_slot(slot_index, item)

func duplicate_slot_to_hotbar(slot_index, item):
	if slot_index < 10:
		hotbar.set_slot(slot_index, item)

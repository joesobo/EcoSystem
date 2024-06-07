extends Panel

signal menu_closed(menu_name, index)
signal items_changed(indexes)

@onready var close_button = %Close
@onready var move_button = %Move

@export var slot_size: int = 0
@export var menu_name: UISingleton.MenuType = UISingleton.MenuType.Storage

var slots: Array[Node] = []
var index: int
var menu: Menu
var follow_mouse_object: Node2D

var is_dragging = false
var drag_offset = Vector2.ZERO

func _ready():
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))
	move_button.connect("gui_input", Callable(self, "_on_move_button_pressed"))

	for i in range(slot_size):
		var slot = %Menu.get_child(0).get_child(i)
		slot.connect("slot_pressed", Callable(self, "_on_slot_pressed"))
		slots.append(slot)

func _process(_delta):
	if follow_mouse_object != null:
		follow_mouse_object.global_position = get_global_mouse_position()

func set_menu(menu: Menu):
	self.menu = menu
	menu.set_size(slot_size)

	for i in range(menu.items.size()):
		var item = menu.items[i]
		set_slot(i, item)

func _on_close_button_pressed():
	emit_signal("menu_closed", UISingleton.get_menu_key(menu_name, index))

func _on_move_button_pressed(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = event.position
			else:
				is_dragging = false
	elif event is InputEventMouseMotion && is_dragging:
		var new_position = global_position + (event.position - drag_offset)
		ensure_within_viewport(new_position)

func _on_slot_pressed(slot_index: int):
	if menu.items[slot_index]:
		follow_mouse_object = menu.items[slot_index].duplicate() as Node2D
		menu.items[slot_index] = {}
	elif follow_mouse_object:
		menu.items[slot_index] = follow_mouse_object
		follow_mouse_object = null
	set_slot(slot_index, menu.items[slot_index])

func set_item(item_index: int, item: Item):
	var previous_item = menu.items[item_index]
	menu.items[item_index] = item
	emit_signal("items_changed", [item_index])
	set_slot(item_index, item)
	return previous_item

func remove_item(item_index: int):
	var previous_item = menu.items[item_index].duplicate()
	menu.items[item_index].clear()
	emit_signal("items_changed", [item_index])
	return previous_item

func add_item_quantity(item_index: int, amount: int):
	menu.items[item_index].quantity += amount

	if menu.items[item_index].quantity <= 0:
		remove_item(item_index)
	else:
		emit_signal("items_changed", [item_index])

func set_slot(item_index: int, item):
	var slot = slots[item_index]
	slot.slotIndex = item_index

	if item is Item:
		slot.set_slot_texture(item)
		slot.set_slot_quantity(item.quantity)
	else:
		slot.clear_slot()

func ensure_within_viewport(new_position: Vector2):
	var viewport_rect = get_viewport_rect()

	var move_button_global_pos = new_position + move_button.position

	# Check horizontal boundaries
	if move_button_global_pos.x < viewport_rect.position.x:
		new_position.x = viewport_rect.position.x - move_button.position.x
	elif move_button_global_pos.x + move_button.size.x > viewport_rect.position.x + viewport_rect.size.x:
		new_position.x = viewport_rect.position.x + viewport_rect.size.x - move_button.size.x - move_button.position.x

	# Check vertical boundaries
	if move_button_global_pos.y < viewport_rect.position.y:
		new_position.y = viewport_rect.position.y - move_button.position.y
	elif move_button_global_pos.y + move_button.size.y > viewport_rect.position.y + viewport_rect.size.y:
		new_position.y = viewport_rect.position.y + viewport_rect.size.y - move_button.size.y - move_button.position.y

	# Update the global position with the corrected position
	global_position = new_position

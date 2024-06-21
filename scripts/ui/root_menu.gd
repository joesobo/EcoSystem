extends Control

signal menu_closed(menu_name, index)
signal update_slot(slot_index, item)

var button_menu
@onready var slot_scene = preload("res://scenes/slot.tscn")

@export var slot_size: int = 0
@export var menu_name: UISingleton.MenuType = UISingleton.MenuType.Storage

var slots: Array[Node] = []
var index: int
var menu: Menu
var dragging_items: bool = false
var start_slot_index: int = -1
var dragged_slots: Array[int] = []
var last_pickup_slot_index: int = -1

var is_dragging = false
var drag_offset = Vector2.ZERO

func _ready():
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

	if has_node("Button Menu"):
		button_menu = get_node("Button Menu")
		button_menu.connect('close_button_pressed', Callable(self, "_on_close_button_pressed"))
		button_menu.connect('move_button_pressed', Callable(self, "_on_move_button_pressed"))

	for i in range(slot_size):
		var slot = %MenuTexture.get_child(i)
		slot.connect("slot_pressed", Callable(self, "_on_slot_pressed"))
		slot.connect("slot_drag_end", Callable(self, "_on_slot_drag_end"))
		slots.append(slot)

func _input(event: InputEvent):
	if dragging_items and event is InputEventMouseMotion:
		for slot in slots:
			# TODO: figure out why the offset is needed
			if slot.get_child(0).get_global_rect().has_point(Vector2(event.position.x, event.position.y + 80)) and !dragged_slots.has(slot.slotIndex):
				if !menu.items[slot.slotIndex] is Item or menu.items[slot.slotIndex].id == UISingleton.follow_mouse_object.item.id:
					dragged_slots.append(slot.slotIndex)

	if event.is_action_pressed("sort_inventory"):
		sort_inventory()

	if event.is_action_pressed("close"):
		_on_close_button_pressed()

func _process(_delta):
	if UISingleton.follow_mouse_object != null:
		UISingleton.follow_mouse_object.global_position = get_global_mouse_position()

func set_menu(menu: Menu):
	self.menu = menu
	menu.set_size(slot_size)

	for i in range(menu.items.size()):
		var item = menu.items[i]
		set_emitted_slot(i, item)

func _on_close_button_pressed():
	var hovered_menu

	for check_menu in UISingleton.menus:
		if check_menu.hovered:
			hovered_menu = check_menu
			break

	if hovered_menu:
		if hovered_menu.key == menu.key:
			handle_escape()
			emit_signal("menu_closed", UISingleton.get_menu_key(menu_name, index))
	else:
		handle_escape()
		emit_signal("menu_closed", UISingleton.get_menu_key(menu_name, index))

func _on_move_button_pressed(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_offset = event.position
		else:
			is_dragging = false
	elif event is InputEventMouseMotion and is_dragging:
		var new_position = get_position() + event.position - drag_offset
		global_position = new_position

func _on_slot_pressed(slot_index: int, event: InputEvent):
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		handle_scroll_down(slot_index)
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		handle_scroll_up(slot_index)

	elif UISingleton.follow_mouse_object:
		dragging_items = true
		start_slot_index = slot_index
		dragged_slots.append(slot_index)
	else:
		handle_item_pickup(slot_index, event)

	set_emitted_slot(slot_index, menu.items[slot_index])

func _on_slot_drag_end(slot_index: int, event: InputEvent):
	if dragging_items:
		if dragged_slots.size() > 1:
			distribute_items_across_slots()
		else:
			handle_item_place(slot_index, event)
	set_emitted_slot(slot_index, menu.items[slot_index])
	reset_dragging()

func _on_mouse_entered():
	menu.hovered = true
	UISingleton.update_menu(menu.key)

func _on_mouse_exited():
	menu.hovered = false
	UISingleton.update_menu(menu.key)

func reset_dragging():
	dragging_items = false
	start_slot_index = -1
	dragged_slots.clear()

func distribute_items_across_slots():
	if UISingleton.follow_mouse_object and dragged_slots.size() >= 1:
		var total_quantity = UISingleton.follow_mouse_object.item.quantity
		var slots_count = dragged_slots.size()
		var items_per_slot = int(total_quantity / slots_count)
		var remainder = total_quantity % slots_count

		var distributed_items = 0

		for i in range(slots_count):
			if distributed_items >= total_quantity:
				break

			var slot_index = dragged_slots[i]
			var quantity_to_place = items_per_slot

			if remainder > 0:
				quantity_to_place += 1
				remainder -= 1

			if quantity_to_place > 0:
				if menu.items[slot_index] is Item and UISingleton.follow_mouse_object.item.id == menu.items[slot_index].id:
					menu.items[slot_index].quantity += quantity_to_place
					slots[slot_index].set_slot_quantity()
					emit_signal("update_slot", slot_index, menu.items[slot_index])
				else:
					place_item_in_empty_slot_quantity(slot_index, quantity_to_place)
				distributed_items += quantity_to_place

		UISingleton.follow_mouse_object.queue_free()
		UISingleton.follow_mouse_object = null

func sort_inventory():
	var combined_items = {}

	# combine items by id
	for slot in slots:
		if slot.item is Item:
			var item = slot.item
			if item.id in combined_items:
				var remaining_quantity = item.quantity
				for combined_item in combined_items[item.id]:
					var available_space = combined_item.max_quantity - combined_item.quantity
					if remaining_quantity <= available_space:
						combined_item.quantity += remaining_quantity
						remaining_quantity = 0
						break
					else:
						remaining_quantity -= available_space
						combined_item.quantity = combined_item.max_quantity

				while remaining_quantity > 0:
					var new_quantity = min(remaining_quantity, item.max_quantity)
					var new_item = item.clone()
					new_item.quantity = new_quantity
					combined_items[item.id].append(new_item)
					remaining_quantity -= new_quantity
			else:
				combined_items[item.id] = [item.clone()]

	# sort combined items
	var sorted_inventory = []
	var sorted_keys = combined_items.keys()
	sorted_keys.sort()

	for key in sorted_keys:
		sorted_inventory += combined_items[key]

	# clear old inventory
	for slot in slots:
		slot.clear_slot()

	# place sorted inventory
	for i in range(sorted_inventory.size()):
		menu.items[i] = sorted_inventory[i]
		set_emitted_slot(i, menu.items[i])

func handle_escape():
	if UISingleton.follow_mouse_object and last_pickup_slot_index != -1:
		menu.items[last_pickup_slot_index] = UISingleton.follow_mouse_object.item
		slots[last_pickup_slot_index].set_item(menu.items[last_pickup_slot_index])

		UISingleton.follow_mouse_object.queue_free()
		UISingleton.follow_mouse_object = null

	last_pickup_slot_index = -1

func init_follow_mouse_slot():
	UISingleton.follow_mouse_object = slot_scene.instantiate()
	UISingleton.follow_mouse_object.z_index = 2
	UISingleton.follow_mouse_object.remove_child(UISingleton.follow_mouse_object.get_child(0))
	UISingleton.add_child(UISingleton.follow_mouse_object)
	UISingleton.follow_mouse_object.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UISingleton.follow_mouse_object.get_child(0).mouse_filter = Control.MOUSE_FILTER_IGNORE

func handle_item_pickup(slot_index: int, event: InputEvent):
	last_pickup_slot_index = slot_index
	if event.button_index == MOUSE_BUTTON_RIGHT and menu.items[slot_index].quantity > 1:
		pickup_half_stack(slot_index)
	elif event.button_index == MOUSE_BUTTON_LEFT:
		pickup_stack(slot_index)

func handle_item_place(slot_index: int, event: InputEvent):
	if event.button_index == MOUSE_BUTTON_LEFT:
		if !menu.items[slot_index] is Item:
			place_item_in_empty_slot(slot_index)
		elif UISingleton.follow_mouse_object.item.id == menu.items[slot_index].id:
			merge_items(slot_index)
		else:
			swap_items(slot_index)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if menu.items[slot_index] is Item and UISingleton.follow_mouse_object.item.id == menu.items[slot_index].id:
			increment_single_item(slot_index)
		elif !menu.items[slot_index] is Item:
			place_single_item_in_empty_slot(slot_index)
		else:
			swap_items(slot_index)

		if UISingleton.follow_mouse_object:
			UISingleton.follow_mouse_object.set_item(UISingleton.follow_mouse_object.item)

func place_item_in_empty_slot(slot_index: int):
	menu.items[slot_index] = UISingleton.follow_mouse_object.item
	UISingleton.follow_mouse_object.queue_free()
	UISingleton.follow_mouse_object = null

func place_item_in_empty_slot_quantity(slot_index: int, quantity: int):
	menu.items[slot_index] = UISingleton.follow_mouse_object.item.clone()
	menu.items[slot_index].quantity = quantity
	set_emitted_slot(slot_index, menu.items[slot_index])

func place_single_item_in_empty_slot(slot_index: int):
	UISingleton.follow_mouse_object.item.quantity -= 1

	menu.items[slot_index] = UISingleton.follow_mouse_object.item.clone()
	menu.items[slot_index].quantity = 1

	if UISingleton.follow_mouse_object.item.quantity == 0:
		UISingleton.follow_mouse_object.queue_free()
		UISingleton.follow_mouse_object = null

func increment_single_item(slot_index: int):
	if menu.items[slot_index].quantity < menu.items[slot_index].max_quantity:
		UISingleton.follow_mouse_object.item.quantity -= 1
		UISingleton.follow_mouse_object.set_slot_quantity()

		menu.items[slot_index].quantity += 1
		emit_signal("update_slot", slot_index, menu.items[slot_index])

		if UISingleton.follow_mouse_object.item.quantity == 0:
			UISingleton.follow_mouse_object.queue_free()
			UISingleton.follow_mouse_object = null

func merge_items(slot_index: int):
	var total_quantity = menu.items[slot_index].quantity + UISingleton.follow_mouse_object.item.quantity

	if total_quantity > menu.items[slot_index].max_quantity:
		menu.items[slot_index].quantity = menu.items[slot_index].max_quantity
		UISingleton.follow_mouse_object.item.quantity = total_quantity - menu.items[slot_index].max_quantity
	else:
		menu.items[slot_index].quantity = total_quantity
		UISingleton.follow_mouse_object.queue_free()
		UISingleton.follow_mouse_object = null

func swap_items(slot_index: int):
	var temp = menu.items[slot_index]
	menu.items[slot_index] = UISingleton.follow_mouse_object.item
	UISingleton.follow_mouse_object.set_item(temp)

func pickup_half_stack(slot_index: int):
	var half_quantity = int(ceil(menu.items[slot_index].quantity / 2))
	var remaining_quantity = menu.items[slot_index].quantity - half_quantity

	init_follow_mouse_slot()

	var cloned_item = menu.items[slot_index].clone()
	cloned_item.quantity = remaining_quantity
	UISingleton.follow_mouse_object.set_item(cloned_item)

	menu.items[slot_index].quantity = half_quantity

func pickup_stack(slot_index: int):
	if menu.items[slot_index] is Item:
		init_follow_mouse_slot()

		UISingleton.follow_mouse_object.set_item(menu.items[slot_index])
		menu.items[slot_index] = {}

# places 1 item into the slot
func handle_scroll_down(slot_index: int):
	if UISingleton.follow_mouse_object:
		if menu.items[slot_index] is Item and UISingleton.follow_mouse_object.item.id == menu.items[slot_index].id:
			increment_single_item(slot_index)
		else:
			place_single_item_in_empty_slot(slot_index)

# removes 1 item from the slot
func handle_scroll_up(slot_index: int):
	if UISingleton.follow_mouse_object and menu.items[slot_index] is Item and UISingleton.follow_mouse_object.item.id == menu.items[slot_index].id:
		UISingleton.follow_mouse_object.item.quantity += 1
		UISingleton.follow_mouse_object.set_slot_quantity()
		menu.items[slot_index].quantity -= 1
		emit_signal("update_slot", slot_index, menu.items[slot_index])

		if (menu.items[slot_index].quantity == 0):
			menu.items[slot_index] = {}
	elif !UISingleton.follow_mouse_object and menu.items[slot_index] is Item:
		init_follow_mouse_slot()

		var cloned_item = menu.items[slot_index].clone()
		cloned_item.quantity = 1
		UISingleton.follow_mouse_object.set_item(cloned_item)

		menu.items[slot_index].quantity -= 1

func set_emitted_slot(slot_index: int, item):
	set_slot(slot_index, item)
	emit_signal("update_slot", slot_index, item)

func set_slot(slot_index: int, item):
	var slot = slots[slot_index]
	slot.slotIndex = slot_index
	menu.items[slot_index] = item

	if item is Item:
		slot.set_item(item)
	else:
		slot.clear_slot()

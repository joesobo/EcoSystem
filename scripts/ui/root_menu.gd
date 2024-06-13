extends Control

signal menu_closed(menu_name, index)

@onready var close_button = %Close
@onready var move_button = %Move
@onready var focus_button = %Focus

@onready var slot_scene = preload("res://scenes/slot.tscn")

@export var slot_size: int = 0
@export var menu_name: UISingleton.MenuType = UISingleton.MenuType.Storage

var slots: Array[Node] = []
var index: int
var menu: Menu
var follow_mouse_object: Panel
var dragging_items: bool = false
var start_slot_index: int = -1
var dragged_slots: Array[int] = []
var last_pickup_slot_index: int = -1

var is_dragging = false
var drag_offset = Vector2.ZERO

func _ready():
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))
	move_button.connect("gui_input", Callable(self, "_on_move_button_pressed"))
	focus_button.connect("pressed", Callable(self, "_on_focus_button_pressed"))

	for i in range(slot_size):
		var slot = %MenuTexture.get_child(i)
		slot.connect("slot_pressed", Callable(self, "_on_slot_pressed"))
		slot.connect("slot_drag_end", Callable(self, "_on_slot_drag_end"))
		slots.append(slot)

func _input(event: InputEvent):
	if dragging_items and event is InputEventMouseMotion:
		for slot in slots:
			if slot.get_child(0).get_global_rect().has_point(event.position) and !dragged_slots.has(slot.slotIndex):
				if !menu.items[slot.slotIndex] is Item or menu.items[slot.slotIndex].id == follow_mouse_object.item.id:
					dragged_slots.append(slot.slotIndex)

	if event.is_action_pressed("sort_inventory"):
		sort_inventory()

	if event.is_action_pressed("close"):
		_on_close_button_pressed()

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
	handle_escape()
	emit_signal("menu_closed", UISingleton.get_menu_key(menu_name, index))

func _on_move_button_pressed(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = event.position
			else:
				is_dragging = false
	elif event is InputEventMouseMotion && is_dragging:
		var new_position = global_position + (event.position - drag_offset)
		ensure_within_viewport(new_position)
	else:
		is_dragging = false

func _on_focus_button_pressed():
	UISingleton.set_focused_menu(menu.key)

func _on_slot_pressed(slot_index: int, event: InputEvent):
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		handle_scroll_down(slot_index)
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		handle_scroll_up(slot_index)

	elif follow_mouse_object:
		dragging_items = true
		start_slot_index = slot_index
		dragged_slots.append(slot_index)
	else:
		handle_item_pickup(slot_index, event)

	set_slot(slot_index, menu.items[slot_index])

func _on_slot_drag_end(slot_index: int, event: InputEvent):
	if dragging_items:
		if dragged_slots.size() > 1:
			distribute_items_across_slots()
		else:
			handle_item_place(slot_index, event)
	set_slot(slot_index, menu.items[slot_index])
	reset_dragging()

func reset_dragging():
	dragging_items = false
	start_slot_index = -1
	dragged_slots.clear()

func distribute_items_across_slots():
	if follow_mouse_object and dragged_slots.size() >= 1:
		var total_quantity = follow_mouse_object.item.quantity
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
				if menu.items[slot_index] is Item and follow_mouse_object.item.id == menu.items[slot_index].id:
					menu.items[slot_index].quantity += quantity_to_place
					slots[slot_index].set_slot_quantity()
				else:
					place_item_in_empty_slot_quantity(slot_index, quantity_to_place)
				distributed_items += quantity_to_place

		follow_mouse_object.queue_free()
		follow_mouse_object = null

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
		set_slot(i, menu.items[i])

func handle_escape():
	if follow_mouse_object and last_pickup_slot_index != -1:
		menu.items[last_pickup_slot_index] = follow_mouse_object.item
		slots[last_pickup_slot_index].set_item(menu.items[last_pickup_slot_index])

		follow_mouse_object.queue_free()
		follow_mouse_object = null

	last_pickup_slot_index = -1

func init_follow_mouse_slot():
	follow_mouse_object = slot_scene.instantiate()
	add_child(follow_mouse_object)
	follow_mouse_object.mouse_filter = Control.MOUSE_FILTER_IGNORE
	follow_mouse_object.get_child(0).mouse_filter = Control.MOUSE_FILTER_IGNORE

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
		elif follow_mouse_object.item.id == menu.items[slot_index].id:
			merge_items(slot_index)
		else:
			swap_items(slot_index)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if menu.items[slot_index] is Item and follow_mouse_object.item.id == menu.items[slot_index].id:
			increment_single_item(slot_index)
		elif !menu.items[slot_index] is Item:
			place_single_item_in_empty_slot(slot_index)
		else:
			swap_items(slot_index)

		if follow_mouse_object:
			follow_mouse_object.set_item(follow_mouse_object.item)

func place_item_in_empty_slot(slot_index: int):
	menu.items[slot_index] = follow_mouse_object.item
	follow_mouse_object.queue_free()
	follow_mouse_object = null

func place_item_in_empty_slot_quantity(slot_index: int, quantity: int):
	menu.items[slot_index] = follow_mouse_object.item.clone()
	menu.items[slot_index].quantity = quantity
	set_slot(slot_index, menu.items[slot_index])

func place_single_item_in_empty_slot(slot_index: int):
	follow_mouse_object.item.quantity -= 1

	menu.items[slot_index] = follow_mouse_object.item.clone()
	menu.items[slot_index].quantity = 1

	if follow_mouse_object.item.quantity == 0:
		follow_mouse_object.queue_free()
		follow_mouse_object = null

func increment_single_item(slot_index: int):
	if menu.items[slot_index].quantity < menu.items[slot_index].max_quantity:
		follow_mouse_object.item.quantity -= 1
		follow_mouse_object.set_slot_quantity()

		menu.items[slot_index].quantity += 1

		if follow_mouse_object.item.quantity == 0:
			follow_mouse_object.queue_free()
			follow_mouse_object = null

func merge_items(slot_index: int):
	var total_quantity = menu.items[slot_index].quantity + follow_mouse_object.item.quantity

	if total_quantity > menu.items[slot_index].max_quantity:
		menu.items[slot_index].quantity = menu.items[slot_index].max_quantity
		follow_mouse_object.item.quantity = total_quantity - menu.items[slot_index].max_quantity
	else:
		menu.items[slot_index].quantity = total_quantity
		follow_mouse_object.queue_free()
		follow_mouse_object = null

func swap_items(slot_index: int):
	var temp = menu.items[slot_index]
	menu.items[slot_index] = follow_mouse_object.item
	follow_mouse_object.set_item(temp)

func pickup_half_stack(slot_index: int):
	var half_quantity = int(ceil(menu.items[slot_index].quantity / 2))
	var remaining_quantity = menu.items[slot_index].quantity - half_quantity

	init_follow_mouse_slot()

	var cloned_item = menu.items[slot_index].clone()
	cloned_item.quantity = remaining_quantity
	follow_mouse_object.set_item(cloned_item)

	menu.items[slot_index].quantity = half_quantity

func pickup_stack(slot_index: int):
	if menu.items[slot_index] is Item:
		init_follow_mouse_slot()

		follow_mouse_object.set_item(menu.items[slot_index])
		menu.items[slot_index] = {}

# places 1 item into the slot
func handle_scroll_down(slot_index: int):
	if follow_mouse_object:
		if menu.items[slot_index] is Item and follow_mouse_object.item.id == menu.items[slot_index].id:
			increment_single_item(slot_index)
		else:
			place_single_item_in_empty_slot(slot_index)

# removes 1 item from the slot
func handle_scroll_up(slot_index: int):
	if follow_mouse_object and menu.items[slot_index] is Item and follow_mouse_object.item.id == menu.items[slot_index].id:
		follow_mouse_object.item.quantity += 1
		follow_mouse_object.set_slot_quantity()
		menu.items[slot_index].quantity -= 1

		if (menu.items[slot_index].quantity == 0):
			menu.items[slot_index] = {}
	elif !follow_mouse_object:
		init_follow_mouse_slot()

		var cloned_item = menu.items[slot_index].clone()
		cloned_item.quantity = 1
		follow_mouse_object.set_item(cloned_item)

		menu.items[slot_index].quantity -= 1

func set_slot(item_index: int, item):
	var slot = slots[item_index]
	slot.slotIndex = item_index

	if item is Item:
		slot.set_item(item)
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

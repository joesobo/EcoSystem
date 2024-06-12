extends Node2D

signal menu_closed(menu_name, index)

@onready var close_button = %Close
@onready var move_button = %Move
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

var is_dragging = false
var drag_offset = Vector2.ZERO

func _ready():
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))
	move_button.connect("gui_input", Callable(self, "_on_move_button_pressed"))

	for i in range(slot_size):
		var slot = %Menu.get_child(0).get_child(i)
		slot.connect("slot_pressed", Callable(self, "_on_slot_pressed"))
		slot.connect("slot_drag_end", Callable(self, "_on_slot_drag_end"))
		slots.append(slot)

func _input(event: InputEvent):
	if dragging_items and event is InputEventMouseMotion:
		for slot in slots:
			if !menu.items[slot.slotIndex] is Item and slot.get_child(0).get_global_rect().has_point(event.position) and !dragged_slots.has(slot.slotIndex):
				dragged_slots.append(slot.slotIndex)

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
			distribute_items_across_slots(event)
		else:
			handle_item_place(slot_index, event)
	set_slot(slot_index, menu.items[slot_index])
	reset_dragging()

func reset_dragging():
	dragging_items = false
	start_slot_index = -1
	dragged_slots.clear()

func distribute_items_across_slots(event: InputEvent):
	if follow_mouse_object and dragged_slots.size() >= 1:
		var total_quantity = follow_mouse_object.item.quantity
		var slots_count = dragged_slots.size()
		var items_per_slot = int(total_quantity / slots_count)
		var remainder = total_quantity % slots_count

		for slot_index in dragged_slots:
			if items_per_slot > 0:
				# TODO: handle merging items
				place_item_in_empty_slot_quantity(slot_index, items_per_slot)

		if remainder > 0:
			menu.items[dragged_slots[0]].quantity += remainder

		follow_mouse_object.queue_free()
		follow_mouse_object = null

func init_follow_mouse_slot():
	follow_mouse_object = slot_scene.instantiate()
	add_child(follow_mouse_object)
	follow_mouse_object.mouse_filter = Control.MOUSE_FILTER_IGNORE
	follow_mouse_object.get_child(0).mouse_filter = Control.MOUSE_FILTER_IGNORE

func handle_item_pickup(slot_index: int, event: InputEvent):
	if event.button_index == MOUSE_BUTTON_RIGHT and menu.items[slot_index].quantity > 1:
		pickup_half_stack(slot_index)
	elif event.button_index == MOUSE_BUTTON_LEFT:
		pickup_stack(slot_index)

func handle_item_place(slot_index: int, event: InputEvent):
	if event.button_index == MOUSE_BUTTON_LEFT:
		if !menu.items[slot_index] is Item:
			place_item_in_empty_slot(slot_index)
		elif follow_mouse_object.item.key == menu.items[slot_index].key:
			merge_items(slot_index)
		else:
			swap_items(slot_index)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if menu.items[slot_index] is Item and follow_mouse_object.item.key == menu.items[slot_index].key:
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
	follow_mouse_object.item.quantity -= 1
	follow_mouse_object.set_slot_quantity()

	menu.items[slot_index].quantity += 1

	if follow_mouse_object.item.quantity == 0:
		follow_mouse_object.queue_free()
		follow_mouse_object = null

func merge_items(slot_index: int):
	menu.items[slot_index].quantity += follow_mouse_object.item.quantity
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
	init_follow_mouse_slot()

	follow_mouse_object.set_item(menu.items[slot_index])
	menu.items[slot_index] = {}

# places 1 item into the slot
func handle_scroll_down(slot_index: int):
	if follow_mouse_object:
		if menu.items[slot_index] is Item and follow_mouse_object.item.key == menu.items[slot_index].key:
			increment_single_item(slot_index)
		else:
			place_single_item_in_empty_slot(slot_index)

# removes 1 item from the slot
func handle_scroll_up(slot_index: int):
	if follow_mouse_object and menu.items[slot_index] is Item and follow_mouse_object.item.key == menu.items[slot_index].key:
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

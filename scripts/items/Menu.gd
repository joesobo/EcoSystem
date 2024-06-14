extends Node

class_name Menu

@export var key: String
@export var position: Vector2
@export var size: int
@export var items: Array = []
@export var opened: bool
@export var focused: bool
@export var hovered: bool
@export var pinned: bool
@export var instance: Node

func _init(key: String, position: Vector2, items: Array, opened: bool, focused: bool, hovered: bool, pinned: bool, instance: Node):
	self.key = key
	self.position = position
	self.items = items
	self.opened = opened
	self.focused = focused
	self.hovered = hovered
	self.pinned = pinned
	self.instance = instance

func set_size(size: int):
	self.size = size

	while items.size() < size:
		items.append({})

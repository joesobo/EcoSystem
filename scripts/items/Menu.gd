extends Node

class_name Menu

@export var key: String
@export var position: Vector2
@export var size: int
@export var items: Array = []
@export var opened: bool
@export var hovered: bool
@export var instance: Node

func _init(key: String, position: Vector2, items: Array, opened: bool, hovered: bool, instance: Node):
	self.key = key
	self.position = position
	self.items = items
	self.opened = opened
	self.hovered = hovered
	self.instance = instance

func set_size(size: int):
	self.size = size

	while items.size() < size:
		items.append({})

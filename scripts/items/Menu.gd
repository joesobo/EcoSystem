extends Node

class_name Menu

@export var key: String
@export var position: Vector2
@export var items: Array = []
@export var opened: bool
@export var focused: bool
@export var instance: Node

func _init(key: String, position: Vector2, items: Array, opened: bool, focused: bool, instance: Node):
	self.key = key
	self.position = position
	self.items = items
	self.opened = opened
	self.focused = focused
	self.instance = instance

extends Node

class_name Item

@export var key: String
@export var label: String
@export var icon: String
@export var stackable: bool
@export var quantity: int = 1
@export var max_quantity: int = 99

func _init(key: String, label: String, icon: String, stackable: bool, quantity: int = 1, max_quantity: int = 99):
	self.key = key
	self.label = label
	self.icon = icon
	self.stackable = stackable
	self.quantity = quantity
	self.max_quantity = max_quantity

func clone() -> Item:
	return Item.new(self.key, self.label, self.icon, self.stackable, self.quantity, self.max_quantity)

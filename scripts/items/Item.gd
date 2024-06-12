extends Node

class_name Item

@export var id: int
@export var label: String
@export var icon: String
@export var stackable: bool
@export var quantity: int = 1
@export var max_quantity: int = 99

func _init(id: int, label: String, icon: String, stackable: bool, quantity: int = 1, max_quantity: int = 99):
	self.id = id
	self.label = label
	self.icon = icon
	self.stackable = stackable
	self.quantity = quantity
	self.max_quantity = max_quantity

func clone() -> Item:
	return Item.new(self.id, self.label, self.icon, self.stackable, self.quantity, self.max_quantity)

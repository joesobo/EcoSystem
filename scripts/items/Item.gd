extends Node

class_name Item

@export var key: String
@export var label: String
@export var icon: String
@export var stackable: bool
@export var quantity: int = 1

func _init(key: String, label: String, icon: String, stackable: bool, quantity: int = 1):
	self.key = key
	self.label = label
	self.icon = icon
	self.stackable = stackable
	self.quantity = quantity

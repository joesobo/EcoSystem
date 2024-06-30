extends Resource

class_name Item

@export var id: int
@export var label: String
@export var icon: Texture
@export var max_quantity: int = 99

var quantity: int = 1

func initialize(id: int, label: String, icon: Texture, quantity: int = 1, max_quantity: int = 99):
	self.id = id
	self.label = label
	self.icon = icon
	self.quantity = quantity
	self.max_quantity = max_quantity

func clone() -> Item:
	var cloned_item = Item.new()
	cloned_item.initialize(self.id, self.label, self.icon, self.quantity, self.max_quantity)
	return cloned_item

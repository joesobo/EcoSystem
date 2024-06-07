extends Node2D

@export var items: Array[Item] = []
var item_file = "res://scripts/items/items.json"

func _ready():
	var json_as_text = FileAccess.get_file_as_string(item_file)
	var item_data = JSON.parse_string(json_as_text)

	for key in item_data.keys():
		var quantity = 1
		if "quantity" in item_data[key]:
			quantity = item_data[key]["quantity"]

		var new_item = Item.new(
			key,
			item_data[key].label,
			item_data[key].icon,
			item_data[key].stackable,
			quantity
		)

		items.append(new_item)

func get_item_by_key(key):
	if items and items.has(key):
		return items[key].duplicate(true)

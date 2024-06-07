extends Node2D

@export var items: Array = []
var item_file = "res://scripts/items/items.json"

func _ready():
	var json_as_text = FileAccess.get_file_as_string(item_file)
	var item_data = JSON.parse_string(json_as_text)

	for key in item_data.keys():
		var new_item = item_data[key]
		new_item["key"] = key

		items.append(new_item)

func get_item_by_key(key):
	if items and items.has(key):
		return items[key].duplicate(true)

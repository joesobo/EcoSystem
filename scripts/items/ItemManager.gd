extends Node

var item_resources = {}

@onready var world_item = preload("res://scenes/world_item.tscn")

func _ready():
	load_resources("res://resources/items")

func load_resources(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var file_path = path + "/" + file_name
				var resource = load(file_path)

				if resource:
					var resource_id = resource.id
					item_resources[resource_id] = resource
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Failed to open directory: ", path)

func create_world_item(item, position, force = Vector2(0, 0)):
	var worldItem = world_item.instantiate()
	worldItem.item = item
	worldItem.global_position = position
	get_tree().root.add_child(worldItem)

	worldItem.apply_impulse(Vector2.ZERO, force)

func get_item(id: int) -> Item:
	return item_resources.get(id, null)

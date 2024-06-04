extends Node2D

@export var fishList: Array[Fish] = []

var fish_file = "res://scripts/genetics/fishDefinitions.json"

func load_fish_data():
	var json_as_text = FileAccess.get_file_as_string(fish_file)
	var fish_data = JSON.parse_string(json_as_text)

	for fish in fish_data.fishSpecies:
		var new_fish = Fish.new(
			fish["name"],
			fish["sprite"],
			fish.get("products", []),
			fish.get("mutations", []),
			fish.get("alleles", []),
			fish.get("restrictions", []),
			fish.get("colors", [])
		)
		fishList.append(new_fish)

func find_template_by_type(type: String) -> Fish:
	for fish in fishList:
		if fish.name == type:
			return fish
	return null

func find_template_by_index(index: int) -> Fish:
	if index < fishList.size():
		return fishList[index]
	return null

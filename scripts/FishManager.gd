extends Node2D

@export var fishCount = 100
@export var fishScenes: Array[PackedScene] = []

var viewport_rect
var fish_data = {}

func _ready():
	viewport_rect = get_viewport_rect()

	load_fish_data()

	for i in range(fishCount):
		spawn_fish()

func load_fish_data():
	var file = "res://scripts/genetics/fishDefinitions.json"
	var json_as_text = FileAccess.get_file_as_string(file)
	fish_data = JSON.parse_string(json_as_text)

func spawn_fish():
	if fishScenes.size() == 0:
		return

	randomize()
	var randomIndex = randi() % fishScenes.size()
	var selectedScene = fishScenes[randomIndex]

	var newFish = selectedScene.instantiate()

	var center = viewport_rect.size * 0.5
	var max_radius = min(viewport_rect.size.x, viewport_rect.size.y) / 4 # Adjust this value as needed
	var angle = randf() * 2 * PI # Random angle in radians
	var radius = sqrt(randf()) * max_radius # Random radius, sqrt for even distribution
	newFish.global_position = center + Vector2(cos(angle), sin(angle)) * radius

	var selectedFishSpecies = fish_data.fishSpecies[0]
	var fish = Fish.new(
		selectedFishSpecies["name"],
		selectedFishSpecies["sprite"],
		selectedFishSpecies.get("products", []),
		selectedFishSpecies.get("mutations", []),
		selectedFishSpecies.get("alleles", {}),
		selectedFishSpecies.get("restrictions", {})
	)

	add_child(newFish)
	newFish.fish = fish
	print(newFish.fish.name)

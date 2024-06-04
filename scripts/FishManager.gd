extends Node2D

@export var fishCount = 100
@export var fishScene: PackedScene
@export var breedingUIScene: PackedScene

var fishScenes: Array = []

var viewport_rect
var breedingUIInstance: Node = null

func _ready():
	viewport_rect = get_viewport_rect()

	FishDefinition.load_fish_data()

	for i in range(fishCount):
		spawn_fish()

func _process(delta):
	if Input.is_action_just_pressed("toggle_menu"):
		if breedingUIInstance == null:
			open_breeding_ui()
		else:
			close_breeding_ui()

func spawn_fish():
	randomize()

	var newFish = fishScene.instantiate()

	var center = viewport_rect.size * 0.5
	var max_radius = min(viewport_rect.size.x, viewport_rect.size.y) / 4 # Adjust this value as needed
	var angle = randf() * 2 * PI # Random angle in radians
	var radius = sqrt(randf()) * max_radius # Random radius, sqrt for even distribution
	newFish.global_position = center + Vector2(cos(angle), sin(angle)) * radius

	add_child(newFish)
	var fish_template = FishDefinition.find_template_by_index(randf() * FishDefinition.fishList.size())
	newFish.fish = fish_template
	newFish.setup()
	fishScenes.append(newFish)

func open_breeding_ui():
	breedingUIInstance = breedingUIScene.instantiate()
	add_child(breedingUIInstance)
	breedingUIInstance.update_label(fishScenes.size())

func close_breeding_ui():
	if breedingUIInstance != null:
		breedingUIInstance.queue_free()
		breedingUIInstance = null

extends Node2D

@export var fishCount = 100
@export var fishScenes: Array[PackedScene] = []
@export var predatorCount = 1
@export var predator: PackedScene

var viewport_rect

func _ready():
	viewport_rect = get_viewport_rect()

	for i in range(fishCount):
		spawn_fish()

	#for i in range(predatorCount):
		#var predatorInstance = predator.instantiate()
		#add_child(predatorInstance)

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

	add_child(newFish)

extends Node2D

@export var fishCount = 100
@export var fishScenes: Array[PackedScene] = []

var viewport_rect

func _ready():
	viewport_rect = get_viewport_rect()
	print(viewport_rect.size)

	for i in range(fishCount):
		spawn_fish()

func spawn_fish():
	if fishScenes.size() == 0:
		return

	randomize()
	var randomIndex = randi() % fishScenes.size()
	var selectedScene = fishScenes[randomIndex]

	var newFish = selectedScene.instantiate()
	newFish.global_position = Vector2(randf() * viewport_rect.size.x, randf() * viewport_rect.size.y)
	add_child(newFish)

extends Node2D

@export var fishCount = 100

@export var fishScene: PackedScene
var viewport_rect

func _ready():
	viewport_rect = get_viewport_rect()

	for i in range(fishCount):
		spawn_fish()

func spawn_fish():
	randomize()
	var newFish = fishScene.instantiate()
	newFish.global_position = Vector2(randf() * viewport_rect.size.x, randf() * viewport_rect.size.y)
	add_child(newFish)


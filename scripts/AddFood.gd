extends Node

@export var foodInstance: PackedScene

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var click_pos = event.global_position
		spawn_food(click_pos)

func spawn_food(pos: Vector2) -> void:
	var food = foodInstance.instantiate()
	food.global_position = pos
	food.rotation_degrees = randf() * 360.0
	add_child(food)

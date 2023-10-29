class_name Voxel

@export var state = false
@export var position: Vector2
@export var x_edge_pos: Vector2
@export var y_edge_pos: Vector2

func _init(x, y, size):
	position = Vector2(x, y) * size

	x_edge_pos = position;
	x_edge_pos.x = position.x + size * 0.5
	y_edge_pos = position;
	y_edge_pos.y = position.y + size * 0.5

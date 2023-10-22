extends Node

@export var voxel_size = 1
@export var voxel_resolution = 8
@export var chunk_resolution = 2
@export var voxel_scene: PackedScene

@export var static_body: StaticBody2D
var collision_shape: CollisionShape2D

var voxels = []

func _ready():
	collision_shape = static_body.get_child(0)
	static_body.connect("input_event", _on_Area2D_input_event)

	for chunk_y in range(chunk_resolution):
		for chunk_x in range(chunk_resolution):
			create_chunk(chunk_x * voxel_resolution, chunk_y * voxel_resolution)

func create_chunk(start_x, start_y):
	var chunk = Node2D.new()
	chunk.name = "Chunk (%d, %d)" % [start_x, start_y]
	add_child(chunk)

	for voxel_y in range(voxel_resolution):
		for voxel_x in range(voxel_resolution):
			create_voxel(chunk, start_x + voxel_x, start_y + voxel_y)

func create_voxel(parent, x, y):
	var voxel = voxel_scene.instantiate()
	parent.add_child(voxel)
	voxel.position = Vector2(x * voxel_size, y * voxel_size)
	voxel.scale = Vector2(voxel_size, voxel_size) * 0.9
	voxel.name = "Voxel (%d, %d)" % [x, y]
	voxels.append(voxel)

func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		edit_voxel(event.position)

func edit_voxel(point: Vector2):
	var voxel_x = floor(point.x / voxel_size)
	var voxel_y = floor(point.y / voxel_size)

	var chunk_x = floor(voxel_x / voxel_resolution)
	var chunk_y = floor(voxel_y / voxel_resolution)

	var local_pos = Vector2(voxel_x - chunk_x * voxel_resolution, voxel_y - chunk_y * voxel_resolution)

	var index = (local_pos.x
		+ local_pos.y * voxel_resolution
		+ chunk_x * voxel_resolution * voxel_resolution
		+ chunk_y * voxel_resolution * voxel_resolution * chunk_resolution)

	print(point)
	print("Voxel: ", Vector2(voxel_x, voxel_y), " Chunk: ", Vector2(chunk_x, chunk_y), " Index: ", index)

	set_voxel(index)

func set_voxel(index):
	toggle_voxel_color(index)

func toggle_voxel_color(index):
	if voxels.size() > index:
		var color = Color.WHITE
		var voxel = voxels[index]

		if voxel.modulate == Color.WHITE:
			color = Color.BLACK
		voxel.modulate = color

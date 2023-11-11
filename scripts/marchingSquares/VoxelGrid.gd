extends Node2D

@export var voxel_size = 1
@export var voxel_resolution = 8
@export var voxel_scene: PackedScene

@export var static_body: StaticBody2D
var collision_shape: CollisionShape2D

var voxels: Array[Voxel] = []
var voxel_pos_indicators = []

var viewport_rect

var mesh_instance
var array_mesh
var arrays = []

var vertices
var indices

func _ready():
	viewport_rect = get_viewport_rect()

	mesh_instance = get_child(1)
	array_mesh = ArrayMesh.new()
	arrays.resize(ArrayMesh.ARRAY_MAX)
	mesh_instance.mesh = array_mesh
	add_child(mesh_instance)

	vertices = PackedVector2Array()
	indices = PackedInt32Array()

	collision_shape = static_body.get_child(0)
	static_body.connect("input_event", _on_Area2D_input_event)

	create_chunk()

	triangulate()

func create_chunk():
	var chunk = Node2D.new()
	chunk.name = "Chunk (0,0)"
	add_child(chunk)

	for voxel_y in range(voxel_resolution):
		for voxel_x in range(voxel_resolution):
			create_voxel(chunk, voxel_x, voxel_y)

func create_voxel(parent, x, y):
	var voxel = voxel_scene.instantiate()
	parent.add_child(voxel)
	voxel.position = Vector2(x * voxel_size, y * voxel_size)
	voxel.scale = Vector2(voxel_size, voxel_size) * 0.1
	voxel.name = "Voxel (%d, %d)" % [x, y]

	voxels.append(Voxel.new(x, y, voxel_size))
	voxel_pos_indicators.append(voxel)

func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		edit_voxel(event.position)

func edit_voxel(point: Vector2):
	var voxel_x = floor(point.x / voxel_size)
	var voxel_y = floor(point.y / voxel_size)

	var local_pos = Vector2(voxel_x, voxel_y)

	var index = local_pos.x+ local_pos.y * voxel_resolution

	set_voxel(index)

func set_voxel(index):
	toggle_voxel_color(index)
	triangulate()

func toggle_voxel_color(index):
	if voxels.size() > index:
		var color = Color.WHITE
		voxels[index].state = !voxels[index].state

		if voxels[index].state:
			color = Color.BLACK

		voxel_pos_indicators[index].modulate = color

func triangulate():
	vertices.clear()
	indices.clear()
	array_mesh = ArrayMesh.new()

	triangulate_chunk()

	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_INDEX] = indices

	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	mesh_instance.mesh = array_mesh

func triangulate_chunk():
	var cells = voxel_resolution - 1

	for cell_y in range(cells):
		for cell_x in range(cells):
			var local_pos = Vector2(cell_x, cell_y)

			var index = local_pos.x + local_pos.y * voxel_resolution

			triangulate_cell(
				voxels[index],
				voxels[index + 1],
				voxels[index + voxel_resolution],
				voxels[index + voxel_resolution + 1]
			)

func triangulate_cell(a: Voxel, b: Voxel, c: Voxel, d: Voxel):
	var cell_type = 0
	if a.state:
		cell_type |= 1;
	if b.state:
		cell_type |= 2;
	if c.state:
		cell_type |= 4;
	if d.state:
		cell_type |= 8;

	if cell_type == 1:
		add_triangle(a.x_edge_pos, a.position, a.y_edge_pos)
	elif cell_type == 2:
		add_triangle(b.y_edge_pos, b.position, a.x_edge_pos)
	elif cell_type == 4:
		add_triangle(a.y_edge_pos, c.position, c.x_edge_pos)
	elif cell_type == 8:
		add_triangle(c.x_edge_pos, d.position, b.y_edge_pos)
	elif cell_type == 3:
		add_quad(b.y_edge_pos, b.position, a.position, a.y_edge_pos)
	elif cell_type == 5:
		add_quad(a.x_edge_pos, a.position, c.position, c.x_edge_pos)
	elif cell_type == 10:
		add_quad(c.x_edge_pos, d.position, b.position, a.x_edge_pos)
	elif cell_type == 12:
		add_quad(a.y_edge_pos, c.position, d.position, b.y_edge_pos)
	elif cell_type == 15:
		add_quad(a.position, c.position, d.position, b.position)
	elif cell_type == 7:
		add_pentagon(b.y_edge_pos, b.position, a.position, c.position, c.x_edge_pos)
	elif cell_type == 11:
		add_pentagon(c.x_edge_pos, d.position, b.position, a.position, a.y_edge_pos)
	elif cell_type == 13:
		add_pentagon(a.x_edge_pos, a.position, c.position, d.position, b.y_edge_pos)
	elif cell_type == 14:
		add_pentagon(a.y_edge_pos, c.position, d.position, b.position, a.x_edge_pos)
	elif cell_type == 6:
		add_triangle(b.y_edge_pos, b.position, a.x_edge_pos);
		add_triangle(a.y_edge_pos, c.position, c.x_edge_pos);
	elif cell_type == 9:
		add_triangle(a.x_edge_pos, a.position, a.y_edge_pos);
		add_triangle(c.x_edge_pos, d.position, b.y_edge_pos);

func add_triangle(a: Vector2, b: Vector2, c: Vector2):
	var vertex_index = vertices.size()
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	indices.append(vertex_index)
	indices.append(vertex_index + 1)
	indices.append(vertex_index + 2)

func add_quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2):
	var vertex_index = vertices.size()
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	vertices.append(d)
	indices.append(vertex_index)
	indices.append(vertex_index + 1)
	indices.append(vertex_index + 2)
	indices.append(vertex_index)
	indices.append(vertex_index + 2)
	indices.append(vertex_index + 3)

func add_pentagon(a: Vector2, b: Vector2, c: Vector2, d: Vector2, e: Vector2):
	var vertex_index = vertices.size()
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	vertices.append(d)
	vertices.append(e)
	indices.append(vertex_index)
	indices.append(vertex_index + 1)
	indices.append(vertex_index + 2)
	indices.append(vertex_index)
	indices.append(vertex_index + 2)
	indices.append(vertex_index + 3)
	indices.append(vertex_index)
	indices.append(vertex_index + 3)
	indices.append(vertex_index + 4)

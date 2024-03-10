extends Node2D

@export var voxel_size = 1
@export var voxel_resolution_x = 8
@export var voxel_resolution_y = 8
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
var triangle_dictionary
var outlines: Array = [[]]
var checked_vertices =  []

func _ready():
	viewport_rect = get_viewport_rect()

	mesh_instance = get_child(1)
	array_mesh = ArrayMesh.new()
	arrays.resize(ArrayMesh.ARRAY_MAX)
	mesh_instance.mesh = array_mesh

	vertices = PackedVector2Array()
	indices = PackedInt32Array()
	triangle_dictionary = {}

	collision_shape = static_body.get_child(0)
	static_body.connect("input_event", _on_Area2D_input_event)

	create_chunk()

	triangulate()

func _draw():
	for outline in outlines:
		for i in range(outline.size() - 1):
			draw_line(vertices[outline[i]], vertices[outline[i + 1]], Color.BLACK, 5)
	
	#for outline in outlines:
		#for i in range(outline.size() - 1):
			#var p1 = vertices[outline[i]]
			#var p2 = vertices[outline[i + 1]]
#
			## Draw lines between the points for debugging
			#draw_line(p1, p2, Color(1, 0, 0), 10) # Red color for visibility
#
			## Optional: Draw normals for debugging
			#var mid_point = (p1 + p2) / 2
			#var normal = (p2 - p1).rotated(PI / 2).normalized() * 10
			##if p1.x == 0 || p2.x == 0:
				##normal = -normal
			#draw_line(mid_point, mid_point + normal, Color(0, 1, 0), 10) # Green color for normals

func create_chunk():
	var chunk = Node2D.new()
	chunk.name = "Chunk (0,0)"
	add_child(chunk)

	for voxel_y in range(voxel_resolution_y):
		for voxel_x in range(voxel_resolution_x):
			create_voxel(chunk, voxel_x, voxel_y)

func create_voxel(parent, x, y):
	var voxel = voxel_scene.instantiate()
	parent.add_child(voxel)
	voxel.position = Vector2(x * voxel_size, y * voxel_size)
	voxel.scale = Vector2(voxel_size, voxel_size) * 0.1
	voxel.name = "Voxel (%d, %d)" % [x, y]
	
	var state = 0
	if (x == 0 || y == 0 || x == voxel_resolution_x-1 || y == voxel_resolution_y-1):
		state = 2
		var index = x + y * voxel_resolution_x
		voxel.modulate = Color.BLACK

	voxels.append(Voxel.new(x, y, voxel_size, state))
	voxel_pos_indicators.append(voxel)

func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		edit_voxel(event.position)
		queue_redraw()

func edit_voxel(point: Vector2):
	var voxel_x = floor(point.x / voxel_size)
	var voxel_y = floor(point.y / voxel_size)

	var local_pos = Vector2(voxel_x, voxel_y)

	var index = local_pos.x + local_pos.y * voxel_resolution_x

	set_voxel(index)

func set_voxel(index):
	toggle_voxel_color(index)
	triangulate()

func toggle_voxel_color(index):
	if voxels.size() > index && voxels[index].state != 2:
		var color = Color.BLACK
		if voxels[index].state == 0:
			voxels[index].state = 1
		elif voxels[index].state == 1:
			voxels[index].state = 0
			color = Color.WHITE

		voxel_pos_indicators[index].modulate = color

func triangulate():
	vertices.clear()
	indices.clear()
	triangle_dictionary.clear()
	outlines.clear()
	checked_vertices.clear()
	array_mesh = ArrayMesh.new()
	
	# remove old child colliders
	while mesh_instance.get_child_count() > 0:
		var child = mesh_instance.get_child(0)
		mesh_instance.remove_child(child)
		child.queue_free()

	triangulate_chunk()

	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_INDEX] = indices

	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	mesh_instance.mesh = array_mesh

	calculate_mesh_outlines()

	for outline in outlines:
		var collider_points = []
		for i in range(outline.size() - 1):
			collider_points.append(vertices[outline[i]])
		collider_points.append(vertices[outline[0]])
		#collider_points.reverse()
		
		var static_body_2d = StaticBody2D.new()
		var collision_polygon = CollisionPolygon2D.new()
		collision_polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
		collision_polygon.polygon = collider_points
		static_body_2d.add_child(collision_polygon)
		mesh_instance.add_child(static_body_2d)
	
func triangulate_chunk():
	for cell_y in range(voxel_resolution_y - 1):
		for cell_x in range(voxel_resolution_x - 1):
			var local_pos = Vector2(cell_x, cell_y)

			var index = local_pos.x + local_pos.y * voxel_resolution_x

			triangulate_cell(
				voxels[index],
				voxels[index + 1],
				voxels[index + voxel_resolution_x],
				voxels[index + voxel_resolution_x + 1]
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
		checked_vertices.append(a.position)
		checked_vertices.append(c.position)
		checked_vertices.append(d.position)
		checked_vertices.append(b.position)
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

func triangle_indices(a_index: int, b_index: int, c_index: int):
	indices.append(a_index)
	indices.append(b_index)
	indices.append(c_index)

	var triangle = Triangle.new(a_index, b_index, c_index)

	add_triangle_to_dictionary(vertices[a_index], triangle)
	add_triangle_to_dictionary(vertices[b_index], triangle)
	add_triangle_to_dictionary(vertices[c_index], triangle)

func add_triangle_to_dictionary(vertice_key, triangle):
	if triangle_dictionary.has(vertice_key):
		triangle_dictionary[vertice_key].append(triangle)
	else:
		triangle_dictionary[vertice_key] = [triangle]

func add_triangle(a: Vector2, b: Vector2, c: Vector2):
	var vertex_index = vertices.size()
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	triangle_indices(vertex_index, vertex_index + 1, vertex_index + 2)

func add_quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2):
	var vertex_index = vertices.size()
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	vertices.append(d)
	triangle_indices(vertex_index, vertex_index + 1, vertex_index + 2)
	triangle_indices(vertex_index, vertex_index + 2, vertex_index + 3)

func add_pentagon(a: Vector2, b: Vector2, c: Vector2, d: Vector2, e: Vector2):
	var vertex_index = vertices.size()
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	vertices.append(d)
	vertices.append(e)
	triangle_indices(vertex_index, vertex_index + 1, vertex_index + 2)
	triangle_indices(vertex_index, vertex_index + 2, vertex_index + 3)
	triangle_indices(vertex_index, vertex_index + 3, vertex_index + 4)

# determine if an edge is an outline edge
func is_outline_edge(vertex_a: Vector2, vertex_b: Vector2):
	var triangles_containing_a: Array = triangle_dictionary[vertex_a]
	var shared_triangle_count = 0

	for triangle in triangles_containing_a:
		if (vertices[triangle.index_a] == vertex_b or
			vertices[triangle.index_b] == vertex_b or
			vertices[triangle.index_c] == vertex_b):
			shared_triangle_count += 1

			if shared_triangle_count > 1:
				break

	return shared_triangle_count == 1

# get the vertex that is connected to the given vertex by an outline edge
func get_connected_outline_index(vertex: Vector2):
	var triangles_containing_vertex: Array = triangle_dictionary[vertex]

	for triangle in triangles_containing_vertex:
		for index in triangle.indices:
			if (vertex != vertices[index] and
				!checked_vertices.has(vertices[index]) and
				is_outline_edge(vertex, vertices[index])):
				return index

	return -1

func follow_outline(index, outline_index):
	outlines[outline_index].append(index)
	checked_vertices.append(vertices[index])
	var next_vertex_index = get_connected_outline_index(vertices[index])

	if next_vertex_index != -1:
		follow_outline(next_vertex_index, outline_index)

func calculate_mesh_outlines():
	checked_vertices.clear()

	for index in range(indices.size()):
		var indice = indices[index]
		var vertice = vertices[indice]
		if !checked_vertices.has(vertice):
			var new_outline_index = get_connected_outline_index(vertice)
			if new_outline_index != -1:
				checked_vertices.append(vertice)

				var new_outline = []
				new_outline.append(indice)
				outlines.append(new_outline)

				follow_outline(new_outline_index, outlines.size() - 1)
				outlines[outlines.size() - 1].append(indice)

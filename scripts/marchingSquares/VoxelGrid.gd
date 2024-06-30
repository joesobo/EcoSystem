extends Node2D

@export var voxel_size = 1
@export var voxel_resolution_x = 8
@export var voxel_resolution_y = 8
@export var voxel_scene: PackedScene
@export var static_body: StaticBody2D
@export var block_textures: Array[Texture2D]

@onready var ui_manager = %"UI Manager"
@onready var player = %"Player"
@onready var camera = player.get_child(2)

var collision_shape: CollisionShape2D

var voxels: Array[Voxel] = []

var viewport_rect

var mesh_instance
var image = Image.new()
var image_texture = ImageTexture.new()
var array_mesh = ArrayMesh.new()
var arrays = []

var vertices = PackedVector2Array()
var indices = PackedInt32Array()
var colors = PackedColorArray()
var triangle_dictionary = {}
var outlines: Array = [[]]
var checked_vertices =  []

# temp terrain for manual testing
# includes padding for x == 0 or y == 0 or y == MAX_SIZE for proper outline normals (NOTE: unsure why this is needed but its the easiest solution rn)
var terrain_states = [
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
	[0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
	[0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
	[0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
	[0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
	[0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1],
	[0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1],
	[0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1],
	[0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1],
	[0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
]

@export var storage_scene = preload("res://scenes/storage_block.tscn")

func _ready():
	viewport_rect = get_viewport_rect()

	mesh_instance = get_child(1)
	arrays.resize(ArrayMesh.ARRAY_MAX)

	var images = []
	for texture in block_textures:
		images.append(texture.get_image())

	var texture_2d_array = Texture2DArray.new()
	texture_2d_array.create_from_images(images)

	mesh_instance.material.set_shader_parameter("texture_array", texture_2d_array)

	mesh_instance.mesh = array_mesh

	collision_shape = static_body.get_child(0)
	static_body.connect("input_event", _on_Area2D_input_event)

	create_chunk()

	triangulate()

# func _draw():
	# for outline in outlines:
	# 	for i in range(outline.size() - 1):
	# 		draw_line(vertices[outline[i]], vertices[outline[i + 1]], Color.BLACK, 1)

	# for outline in outlines:
	# 	for i in range(outline.size() - 1):
	# 		var p1 = vertices[outline[i]]
	# 		var p2 = vertices[outline[i + 1]]

	# 		# Draw lines between the points for debugging
	# 		# draw_line(p1, p2, Color(1, 0, 0), 10) # Red color for visibility

	# 		# Optional: Draw normals for debugging
	# 		var mid_point = (p1 + p2) / 2
	# 		var normal = Vector2(p2.y - p1.y, p1.x - p2.x).normalized() * 10

	# 		draw_line(mid_point, mid_point + normal, Color(0, 1, 0), 2) # Green color for normals

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
	voxel.scale = Vector2(voxel_size, voxel_size)
	voxel.name = "Voxel (%d, %d)" % [x, y]

	var state = terrain_states[y][x]

	voxels.append(Voxel.new(x, y, voxel_size, state))

func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_position = camera.get_global_mouse_position()

		var voxel_x = round(world_position.x / voxel_size)
		var voxel_y = round(world_position.y / voxel_size)
		var index = voxel_x + voxel_y * voxel_resolution_x
		if Input.is_action_pressed("place_storage") && voxels[index].state == 0.0:
			var storage = storage_scene.instantiate()
			storage.position = Vector2(voxel_x, voxel_y) * voxel_size

			add_child(storage)

			voxels[index].state = -1.0
			UISingleton.storage_map[index] = storage
		elif Input.is_action_pressed("place_storage") && voxels[index].state == -1.0:
			UISingleton.storage_map[index].queue_free()
			voxels[index].state = 0.0
			UISingleton.storage_map.erase(index)
		elif voxels[index].state == -1.0:
			# open UI
			ui_manager.toggle_menu(UISingleton.MenuType.Storage, index)
		elif !UISingleton.storage_map.has(index):
			edit_voxel(world_position)

		queue_redraw()

func edit_voxel(point: Vector2):
	var voxel_x = round(point.x / voxel_size)
	var voxel_y = round(point.y / voxel_size)

	if voxel_x == 0 or voxel_y == 0 or voxel_y == voxel_resolution_y - 1:
		return

	set_voxel(Vector2(voxel_x, voxel_y))

func set_voxel(local_pos: Vector2):
	toggle_voxel_color(local_pos)
	triangulate()

func toggle_voxel_color(local_pos: Vector2):
	var index = local_pos.x + local_pos.y * voxel_resolution_x

	if voxels.size() > index && voxels[index].state != 2.0:
		if voxels[index].state == 0.0:
			voxels[index].state = 1.0
		elif voxels[index].state == 1.0:
			voxels[index].state = 0.0

func triangulate():
	vertices.clear()
	indices.clear()
	colors.clear()
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
	arrays[ArrayMesh.ARRAY_COLOR] = colors

	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	mesh_instance.mesh = array_mesh

	calculate_mesh_outlines()

	for outline in outlines:
		var collider_points = []
		for i in range(outline.size() - 1):
			collider_points.append(vertices[outline[i]])
		collider_points.append(vertices[outline[0]])

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

func is_multi_material(aState: float, bState: float, cState: float, dState: float):
	if aState == 0 and bState == 0 and cState == 0 and dState == 0:
		return false

	var value = dState
	if aState > 0:
		value = aState
	elif bState > 0:
		value = bState
	elif cState > 0:
		value = cState

	if (aState == value or aState == 0) and (bState == value or bState == 0) and (cState == value or cState == 0) and (dState == value or dState == 0):
		return false

	return true

func triangulate_cell(a: Voxel, b: Voxel, c: Voxel, d: Voxel):
	var aState = a.state
	var bState = b.state
	var cState = c.state
	var dState = d.state

	var aColor = Color(aState / 255, 0, 0)
	var bColor = Color(bState / 255, 0, 0)
	var cColor = Color(cState / 255, 0, 0)
	var dColor = Color(dState / 255, 0, 0)

	var multi_material = is_multi_material(aState, bState, cState, dState)

	var half_length = a.x_edge_pos.x - a.position.x
	var quarter_length = half_length / 2

	var center = Vector2(a.x_edge_pos.x, a.y_edge_pos.y)
	var a_inner = center + Vector2(-quarter_length, -quarter_length)
	var b_inner = center + Vector2(quarter_length, -quarter_length)
	var c_inner = center + Vector2(-quarter_length, quarter_length)
	var d_inner = center + Vector2(quarter_length, quarter_length)

	var cell_type = 0

	if aState > 0:
		cell_type |= 1
	if bState > 0:
		cell_type |= 2
	if cState > 0:
		cell_type |= 4
	if dState > 0:
		cell_type |= 8

	# multi material full-cell types
	if cell_type >= 15 and multi_material:
		if cState != aState and aState == bState and aState == dState:
			cell_type = 16
		elif aState == bState and aState == cState and aState != dState:
			cell_type = 17
		elif aState != bState and bState == cState and bState == dState:
			cell_type = 18
		elif aState == cState and aState == dState and aState != bState:
			cell_type = 19
		elif aState != bState and aState != cState and bState == dState and cState != dState:
			cell_type = 20
		elif aState == cState and aState != bState and aState != dState and bState != dState:
			cell_type = 21
		elif aState != bState and aState != cState and bState != cState and cState == dState:
			cell_type = 22
		elif aState == bState and aState != cState and aState != dState and cState != dState:
			cell_type = 23
		elif aState != bState and aState == cState and bState == dState:
			cell_type = 24
		elif aState == bState and cState == dState and aState != cState:
			cell_type = 25
		elif aState != bState and aState != cState and aState != dState and bState != cState and bState != dState and cState != dState:
			cell_type = 26

	if !multi_material:
		if cell_type == 1:
			add_triangle(a.x_edge_pos, a.position, a.y_edge_pos, aColor)
		elif cell_type == 2:
			add_triangle(b.y_edge_pos, b.position, a.x_edge_pos, bColor)
		elif cell_type == 4:
			add_triangle(a.y_edge_pos, c.position, c.x_edge_pos, cColor)
		elif cell_type == 8:
			add_triangle(c.x_edge_pos, d.position, b.y_edge_pos, dColor)
		elif cell_type == 3:
			add_quad(b.y_edge_pos, b.position, a.position, a.y_edge_pos, aColor)
		elif cell_type == 5:
			add_quad(a.x_edge_pos, a.position, c.position, c.x_edge_pos, aColor)
		elif cell_type == 10:
			add_quad(c.x_edge_pos, d.position, b.position, a.x_edge_pos, dColor)
		elif cell_type == 12:
			add_quad(a.y_edge_pos, c.position, d.position, b.y_edge_pos, cColor)
		elif cell_type == 15:
			checked_vertices.append(a.position)
			checked_vertices.append(c.position)
			checked_vertices.append(d.position)
			checked_vertices.append(b.position)
			add_quad(a.position, c.position, d.position, b.position, aColor)
		elif cell_type == 7:
			add_pentagon(b.y_edge_pos, b.position, a.position, c.position, c.x_edge_pos, bColor)
		elif cell_type == 11:
			add_pentagon(c.x_edge_pos, d.position, b.position, a.position, a.y_edge_pos, dColor)
		elif cell_type == 13:
			add_pentagon(a.x_edge_pos, a.position, c.position, d.position, b.y_edge_pos, aColor)
		elif cell_type == 14:
			add_pentagon(a.y_edge_pos, c.position, d.position, b.position, a.x_edge_pos, cColor)
		elif cell_type == 6:
			add_triangle(b.y_edge_pos, b.position, a.x_edge_pos, bColor)
			add_triangle(a.y_edge_pos, c.position, c.x_edge_pos, cColor)
		elif cell_type == 9:
			add_triangle(a.x_edge_pos, a.position, a.y_edge_pos, aColor)
			add_triangle(c.x_edge_pos, d.position, b.y_edge_pos, dColor)
	# multi material triangles
	else:
		if cell_type == 3:
			add_triangle(center, a.y_edge_pos, a.x_edge_pos, aColor)
			add_triangle(a.y_edge_pos, a.position, a.x_edge_pos, aColor)

			add_triangle(b.y_edge_pos, center, b.position, bColor)
			add_triangle(center, a.x_edge_pos, b.position, bColor)
		elif cell_type == 5:
			add_triangle(c.x_edge_pos, c.position, center, cColor)
			add_triangle(c.position, a.y_edge_pos, center, cColor)

			add_triangle(center, a.y_edge_pos, a.x_edge_pos, aColor)
			add_triangle(a.y_edge_pos, a.position, a.x_edge_pos, aColor)
		elif cell_type == 10:
			add_triangle(d.position, c.x_edge_pos, b.y_edge_pos, dColor)
			add_triangle(c.x_edge_pos, center, b.y_edge_pos, dColor)

			add_triangle(b.y_edge_pos, center, b.position, bColor)
			add_triangle(center, a.x_edge_pos, b.position, bColor)
		elif cell_type == 12:
			add_triangle(c.x_edge_pos, c.position, center, cColor)
			add_triangle(c.position, a.y_edge_pos, center, cColor)

			add_triangle(d.position, c.x_edge_pos, b.y_edge_pos, dColor)
			add_triangle(c.x_edge_pos, center, b.y_edge_pos, dColor)
		elif cell_type == 6:
			add_triangle(b.y_edge_pos, b.position, a.x_edge_pos, bColor)

			add_triangle(a.y_edge_pos, c.position, c.x_edge_pos, cColor)
		elif cell_type == 9:
			add_triangle(a.x_edge_pos, a.position, a.y_edge_pos, aColor)

			add_triangle(c.x_edge_pos, d.position, b.y_edge_pos, dColor)
		elif cell_type == 7:
			add_triangle(c.x_edge_pos, c.position, center, cColor)
			add_triangle(c.position, a.y_edge_pos, center, cColor)
			add_triangle(c.x_edge_pos, center, d_inner, cColor)

			add_triangle(center, a.y_edge_pos, a.x_edge_pos, aColor)
			add_triangle(a.y_edge_pos, a.position, a.x_edge_pos, aColor)

			add_triangle(b.y_edge_pos, d_inner, center, bColor)
			add_triangle(b.y_edge_pos, center, b.position, bColor)
			add_triangle(center, a.x_edge_pos, b.position, bColor)
		elif cell_type == 11:
			add_triangle(d.position, c.x_edge_pos, b.y_edge_pos, dColor)
			add_triangle(c.x_edge_pos, center, b.y_edge_pos, dColor)
			add_triangle(c.x_edge_pos, c_inner, center, dColor)

			add_triangle(c_inner, a.y_edge_pos, center, aColor)
			add_triangle(center, a.y_edge_pos, a.x_edge_pos, aColor)
			add_triangle(a.y_edge_pos, a.position, a.x_edge_pos, aColor)

			add_triangle(b.y_edge_pos, center, b.position, bColor)
			add_triangle(center, a.x_edge_pos, b.position, bColor)
		elif cell_type == 13:
			add_triangle(c.x_edge_pos, c.position, center, cColor)
			add_triangle(c.position, a.y_edge_pos, center, cColor)

			add_triangle(d.position, c.x_edge_pos, b.y_edge_pos, dColor)
			add_triangle(c.x_edge_pos, center, b.y_edge_pos, dColor)
			add_triangle(b.y_edge_pos, center, b_inner, dColor)

			add_triangle(center, a.y_edge_pos, a.x_edge_pos, aColor)
			add_triangle(a.y_edge_pos, a.position, a.x_edge_pos, aColor)
			add_triangle(center, a.x_edge_pos, b_inner, aColor)
		elif cell_type == 14:
			add_triangle(c.x_edge_pos, c.position, center, cColor)
			add_triangle(center, c.position, a.y_edge_pos, cColor)
			add_triangle(center, a.y_edge_pos, a_inner, cColor)

			add_triangle(d.position, c.x_edge_pos, b.y_edge_pos, dColor)
			add_triangle(b.y_edge_pos, c.x_edge_pos, center, dColor)

			add_triangle(b.y_edge_pos, center, b.position, bColor)
			add_triangle(center, a.x_edge_pos, b.position, bColor)
			add_triangle(center, a_inner, a.x_edge_pos, bColor)
		elif cell_type == 16:
			checked_vertices.append(c.x_edge_pos)
			checked_vertices.append(a.y_edge_pos)
			checked_vertices.append(c.position)
			checked_vertices.append(d.position)
			checked_vertices.append(b.position)
			checked_vertices.append(a.position)
			add_triangle(c.x_edge_pos, c.position, a.y_edge_pos, cColor)

			add_triangle(d.position, c.x_edge_pos, b.position, dColor)
			add_triangle(c.x_edge_pos, a.y_edge_pos, b.position, bColor)
			add_triangle(a.y_edge_pos, a.position, b.position, aColor)
		elif cell_type == 17:
			checked_vertices.append(d.position)
			checked_vertices.append(c.x_edge_pos)
			checked_vertices.append(b.y_edge_pos)
			checked_vertices.append(c.position)
			checked_vertices.append(a.position)
			checked_vertices.append(b.position)
			add_triangle(d.position, c.x_edge_pos, b.y_edge_pos, dColor)

			add_triangle(c.x_edge_pos, c.position, a.position, cColor)
			add_triangle(c.x_edge_pos, a.position, b.y_edge_pos, aColor)
			add_triangle(b.y_edge_pos, a.position, b.position, bColor)
		elif cell_type == 18:
			checked_vertices.append(a.y_edge_pos)
			checked_vertices.append(a.x_edge_pos)
			checked_vertices.append(c.position)
			checked_vertices.append(d.position)
			checked_vertices.append(b.position)
			checked_vertices.append(a.position)
			add_triangle(d.position, c.position, a.y_edge_pos, cColor)
			add_triangle(d.position, a.y_edge_pos, a.x_edge_pos, dColor)
			add_triangle(d.position, a.x_edge_pos, b.position, bColor)

			add_triangle(a.y_edge_pos, a.position, a.x_edge_pos, aColor)
		elif cell_type == 19:
			checked_vertices.append(c.position)
			checked_vertices.append(d.position)
			checked_vertices.append(b.position)
			checked_vertices.append(a.position)
			checked_vertices.append(b.y_edge_pos)
			checked_vertices.append(a.x_edge_pos)
			add_triangle(d.position, c.position, b.y_edge_pos, dColor)
			add_triangle(b.y_edge_pos, c.position, a.x_edge_pos, cColor)
			add_triangle(a.x_edge_pos, c.position, a.position, aColor)

			add_triangle(b.y_edge_pos, a.x_edge_pos, b.position, bColor)
		elif cell_type == 20:
			checked_vertices.append(c.x_edge_pos)
			checked_vertices.append(c.position)
			checked_vertices.append(center)
			checked_vertices.append(a.y_edge_pos)
			checked_vertices.append(a.x_edge_pos)
			checked_vertices.append(d.position)
			checked_vertices.append(b.position)
			checked_vertices.append(a.position)
			add_triangle(c.x_edge_pos, c.position, center, cColor)
			add_triangle(c.position, a.y_edge_pos, center, cColor)

			add_triangle(center, a.y_edge_pos, a.x_edge_pos, aColor)
			add_triangle(a.y_edge_pos, a.position, a.x_edge_pos, aColor)

			add_triangle(d.position, c.x_edge_pos, b.position, dColor)
			add_triangle(b.position, c.x_edge_pos, a.x_edge_pos, bColor)
		elif cell_type == 21:
			checked_vertices.append(c.position)
			checked_vertices.append(d.position)
			checked_vertices.append(b.position)
			checked_vertices.append(a.position)
			checked_vertices.append(center)
			checked_vertices.append(c.x_edge_pos)
			checked_vertices.append(a.x_edge_pos)
			checked_vertices.append(b.y_edge_pos)
			add_triangle(c.x_edge_pos, c.position, a.x_edge_pos, cColor)
			add_triangle(c.position, a.position, a.x_edge_pos, aColor)

			add_triangle(d.position, c.x_edge_pos, b.y_edge_pos, dColor)
			add_triangle(c.x_edge_pos, center, b.y_edge_pos, dColor)

			add_triangle(b.y_edge_pos, center, b.position, bColor)
			add_triangle(center, a.x_edge_pos, b.position, bColor)
		elif cell_type == 22:
			checked_vertices.append(c.position)
			checked_vertices.append(d.position)
			checked_vertices.append(b.position)
			checked_vertices.append(a.position)
			checked_vertices.append(center)
			checked_vertices.append(b.y_edge_pos)
			checked_vertices.append(a.y_edge_pos)
			checked_vertices.append(a.x_edge_pos)
			add_triangle(d.position, c.position, b.y_edge_pos, dColor)
			add_triangle(c.position, a.y_edge_pos, b.y_edge_pos, cColor)

			add_triangle(center, a.y_edge_pos, a.x_edge_pos, aColor)
			add_triangle(a.y_edge_pos, a.position, a.x_edge_pos, aColor)

			add_triangle(b.y_edge_pos, center, b.position, bColor)
			add_triangle(center, a.x_edge_pos, b.position, bColor)
		elif cell_type == 23:
			checked_vertices.append(c.position)
			checked_vertices.append(d.position)
			checked_vertices.append(b.position)
			checked_vertices.append(a.position)
			checked_vertices.append(center)
			checked_vertices.append(c.x_edge_pos)
			checked_vertices.append(a.y_edge_pos)
			checked_vertices.append(b.y_edge_pos)
			add_triangle(c.x_edge_pos, c.position, center, cColor)
			add_triangle(center, c.position, a.y_edge_pos, cColor)

			add_triangle(d.position, c.x_edge_pos, b.y_edge_pos, dColor)
			add_triangle(c.x_edge_pos, center, b.y_edge_pos, dColor)

			add_triangle(b.y_edge_pos, a.y_edge_pos, b.position, bColor)
			add_triangle(b.position, a.y_edge_pos, a.position, aColor)
		elif cell_type == 24:
			checked_vertices.append(c.position)
			checked_vertices.append(d.position)
			checked_vertices.append(b.position)
			checked_vertices.append(a.position)
			checked_vertices.append(c.x_edge_pos)
			checked_vertices.append(a.x_edge_pos)
			add_triangle(c.x_edge_pos, c.position, a.x_edge_pos, cColor)
			add_triangle(c.position, a.position, a.x_edge_pos, aColor)

			add_triangle(d.position, c.x_edge_pos, b.position, dColor)
			add_triangle(c.x_edge_pos, a.x_edge_pos, b.position, bColor)
		elif cell_type == 25:
			checked_vertices.append(c.position)
			checked_vertices.append(d.position)
			checked_vertices.append(b.position)
			checked_vertices.append(a.position)
			checked_vertices.append(b.y_edge_pos)
			checked_vertices.append(a.y_edge_pos)
			add_triangle(d.position, c.position, b.y_edge_pos, dColor)
			add_triangle(b.y_edge_pos, c.position, a.y_edge_pos, cColor)

			add_triangle(b.y_edge_pos, a.y_edge_pos, b.position, bColor)
			add_triangle(b.position, a.y_edge_pos, a.position, aColor)
		elif cell_type == 26:
			checked_vertices.append(c.position)
			checked_vertices.append(d.position)
			checked_vertices.append(b.position)
			checked_vertices.append(a.position)
			checked_vertices.append(center)
			checked_vertices.append(c.x_edge_pos)
			checked_vertices.append(b.y_edge_pos)
			checked_vertices.append(a.y_edge_pos)
			checked_vertices.append(a.x_edge_pos)

			add_triangle(d.position, c.x_edge_pos, b.y_edge_pos, dColor)
			add_triangle(b.y_edge_pos, c.x_edge_pos, center, dColor)

			add_triangle(c.x_edge_pos, c.position, center, cColor)
			add_triangle(center, c.position, a.y_edge_pos, cColor)

			add_triangle(b.y_edge_pos, center, b.position, bColor)
			add_triangle(b.position, center, a.x_edge_pos, bColor)

			add_triangle(a.x_edge_pos, center, a.y_edge_pos, aColor)
			add_triangle(a.x_edge_pos, a.y_edge_pos, a.position, aColor)

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

func add_triangle(a: Vector2, b: Vector2, c: Vector2, color: Color):
	var vertex_index = vertices.size()
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	colors.append(color)
	colors.append(color)
	colors.append(color)
	triangle_indices(vertex_index, vertex_index + 1, vertex_index + 2)

func add_quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color):
	var vertex_index = vertices.size()
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	vertices.append(d)
	colors.append(color)
	colors.append(color)
	colors.append(color)
	colors.append(color)
	triangle_indices(vertex_index, vertex_index + 1, vertex_index + 2)
	triangle_indices(vertex_index, vertex_index + 2, vertex_index + 3)

func add_pentagon(a: Vector2, b: Vector2, c: Vector2, d: Vector2, e: Vector2, color: Color):
	var vertex_index = vertices.size()
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	vertices.append(d)
	vertices.append(e)
	colors.append(color)
	colors.append(color)
	colors.append(color)
	colors.append(color)
	colors.append(color)
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

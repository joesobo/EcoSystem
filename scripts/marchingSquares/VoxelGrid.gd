extends Node

@export var voxelSize = 1
@export var voxelResolution = 8
@export var chunkResolution = 2
@export var voxelScene: PackedScene

@export var staticBody: StaticBody2D
var collisionShape: CollisionShape2D

var voxels = []

func _ready():
	collisionShape = staticBody.get_child(0)
	staticBody.connect("input_event", _on_Area2D_input_event)

	for chunkY in range(chunkResolution):
		for chunkX in range(chunkResolution):
			CreateChunk(chunkX * voxelResolution, chunkY * voxelResolution)

func CreateChunk(startX, startY):
	var chunk = Node2D.new()
	chunk.name = "Chunk (%d, %d)" % [startX, startY]
	add_child(chunk)

	for voxelY in range(voxelResolution):
		for voxelX in range(voxelResolution):
			CreateVoxel(chunk, startX + voxelX, startY + voxelY)

func CreateVoxel(parent, x, y):
	var voxel = voxelScene.instantiate()
	parent.add_child(voxel)
	voxel.position = Vector2(x * voxelSize, y * voxelSize)
	voxel.scale = Vector2(voxelSize, voxelSize)
	voxel.name = "Voxel (%d, %d)" % [x, y]
	voxels.append(voxel)

func _on_Area2D_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		EditVoxel(event.position)

func EditVoxel(point: Vector2):
	var voxelX = floor(point.x / voxelSize)
	var voxelY = floor(point.y / voxelSize)

	var chunkX = floor(voxelX / voxelResolution)
	var chunkY = floor(voxelY / voxelResolution)

	var index = voxelY * voxelResolution + voxelX + chunkX * chunkResolution * voxelResolution + chunkY * chunkResolution * voxelResolution * voxelResolution

	# print("Voxel: ", Vector2(voxelX, voxelY), " Chunk: ", Vector2(chunkX, chunkY), " Index: ", index)

	SetVoxel(index, true)

func SetVoxel(index, state: bool):
	SetVoxelColor(index, state if Color.BLACK else Color.WHITE)

func SetVoxelColor(index, color):
	if voxels.size() > index:
		var voxel = voxels[index]
		voxel.modulate = Color.BLACK
		print(voxel, voxel.modulate)

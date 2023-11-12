class_name Triangle

@export var index_a: int
@export var index_b: int
@export var index_c: int
var indices: Array[int] = []

func _init(a, b, c):
	index_a = a
	index_b = b
	index_c = c

	indices.append(index_a)
	indices.append(index_b)
	indices.append(index_c)

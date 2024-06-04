extends Resource

class_name Fish

@export var name: String
@export var sprite: String
@export var products: Array
@export var mutations: Array
@export var alleles: Array
@export var restrictions: Array
@export var colors: Array

func _init(name: String, sprite: String, products: Array, mutations: Array, alleles: Array, restrictions: Array, colors: Array):
	self.name = name
	self.sprite = sprite
	self.products = products
	self.mutations = mutations
	self.alleles = alleles
	self.restrictions = restrictions
	self.colors = colors

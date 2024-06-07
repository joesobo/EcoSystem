extends RigidBody2D

var siteArea: Area2D
var siteCollisionShape: CollisionShape2D

@export var visualRange = 50
@export var type = 'blue'

func _ready():
	siteArea = get_child(2)
	siteCollisionShape = siteArea.get_child(0)
	siteCollisionShape.shape.radius = visualRange

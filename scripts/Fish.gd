extends RigidBody2D

var siteArea: Area2D
var siteCollisionShape: CollisionShape2D

@export var visualRange = 50
@export var type = 'blue'

func _ready():
	siteArea = get_child(2)
	siteCollisionShape = siteArea.get_child(0)
	siteCollisionShape.shape.radius = visualRange

	siteArea.connect("body_entered", _on_Area2D_site_body_entered)
	#siteArea.connect("body_exited", _on_Area2D_site_body_exited)

func _on_Area2D_site_body_entered(body):
	print(body)
	# 
	
#func _on_Area2D_site_body_exited(body):
	#body.queue_free()

func _process(delta):
	pass

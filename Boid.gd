extends RigidBody2D

@export var maxSpeed = 400
@export var speed = 0
@export var velocity: Vector2

@export var avoidRadius = 20
@export var visualRange = 50
@export var turnSpeed = 0.1

@export var randomForce = 0.05
@export var cohesionForce: = 0.005
@export var alignmentForce: = 0.05
@export var separationForce: = 0.05

var flock = []

var viewport_rect

func _ready():
	randomize()
	
	var area2D: Area2D = get_child(2)
	viewport_rect = get_viewport_rect()
	
	var collision_shape: CollisionShape2D = area2D.get_child(0)
	collision_shape.shape.radius = avoidRadius
	
	area2D.connect("area_entered", _on_Area2D_area_entered)
	area2D.connect("area_exited", _on_Area2D_area_exited)

	
	speed = randf_range(maxSpeed / 2, maxSpeed)
	velocity = randomVelocity()
	
	modulate = Color(randf(), randf(), randf(), 1)

func _on_Area2D_area_entered(area):
	if area != self and area not in flock:
		flock.append(area.get_parent())

func _on_Area2D_area_exited(area):
	if area.get_parent() in flock:
		flock.erase(area.get_parent())

func handle_borders():
	if global_position.x < viewport_rect.position.x:
		global_position.x = viewport_rect.position.x + viewport_rect.size.x
	elif global_position.x > viewport_rect.position.x + viewport_rect.size.x:
		global_position.x = viewport_rect.position.x

	if global_position.y < viewport_rect.position.y:
		global_position.y = viewport_rect.position.y + viewport_rect.size.y
	elif global_position.y > viewport_rect.position.y + viewport_rect.size.y:
		global_position.y = viewport_rect.position.y

func _physics_process(delta):
	handle_borders()
	
	velocity += randomVelocity() * randomForce
	velocity += separation() * separationForce
	velocity += alignment() * alignmentForce
	velocity += cohesion() * cohesionForce
	#velocity += borderForce()
	
	velocity = velocity.lerp(velocity + alignment() * alignmentForce, turnSpeed)
	velocity = velocity.normalized() * min(velocity.length(), speed)

	set_linear_velocity(velocity)

func separation():
	var avoidVector = Vector2()
	
	for flockMate in flock:
		var flockMatePosition = flockMate.global_position
		
		var distance = global_position.distance_to(flockMatePosition)
		if (distance < avoidRadius and distance > 0):
			avoidVector -= (flockMatePosition - global_position).normalized() * (avoidRadius / distance * speed)
			
	return avoidVector

func alignment():
	var numNeighbors = 0
	var alignVector = Vector2()

	for flockMate in flock:
		if (global_position.distance_to(flockMate.global_position) < visualRange):
			alignVector += flockMate.velocity
			numNeighbors += 1

	if (numNeighbors > 0):
		alignVector /= numNeighbors

	return alignVector

func cohesion():
	var numNeighbors = 0
	var centerVector = Vector2()

	for flockMate in flock:
		if (global_position.distance_to(flockMate.global_position) < visualRange):
			centerVector += flockMate.global_position
			numNeighbors += 1

	if (numNeighbors):
		centerVector /= numNeighbors
		
	return centerVector

func randomVelocity():
	return Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed

func borderForce():
	var borderVelocity = Vector2()
	var inset = 10
	
	var distance_to_left_border = global_position.x - (viewport_rect.position.x + inset)
	var distance_to_right_border = (viewport_rect.position.x + viewport_rect.size.x - inset) - global_position.x
	var distance_to_top_border = global_position.y - (viewport_rect.position.y + inset)
	var distance_to_bottom_border = (viewport_rect.position.y + viewport_rect.size.y - inset) - global_position.y

	if distance_to_left_border < avoidRadius:
		borderVelocity.x = ((avoidRadius - distance_to_left_border) / avoidRadius) * speed
	elif distance_to_right_border < avoidRadius:
		borderVelocity.x = (-(avoidRadius - distance_to_right_border) / avoidRadius) * speed
		
	if distance_to_top_border < avoidRadius:
		borderVelocity.y = ((avoidRadius - distance_to_top_border) / avoidRadius) * speed
	elif distance_to_bottom_border < avoidRadius:
		borderVelocity.y = (-(avoidRadius - distance_to_bottom_border) / avoidRadius) * speed


	return borderVelocity

extends RigidBody2D

@export var maxSpeed = 200
@export var speed = 0
@export var velocity: Vector2

@export var avoidRadius = 30
@export var visualRange = 50
@export var turnSpeed = 1

@export var randomForce = 0.05
@export var cohesionForce: = 0.005
@export var alignmentForce: = 0.05
@export var separationForce: = 0.05

@export var viewAngle = 45

@export var color_palette = [
	Color(0.0, 0.4, 0.8, 1.0),  # Blue
	Color(0.0, 0.6, 0.9, 1.0),  # Lighter Blue
	Color(0.0, 0.3, 0.6, 1.0),  # Darker Blue
	Color(0.0, 0.2, 0.5, 1.0),  # Even Darker Blue
	Color(0.0, 0.1, 0.3, 1.0),  # Darkest Blue
]
@export var type = 'Blue'

var flock = []
var viewport_rect

var debug_point_radius = 7.0
var debug_point_color

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

	debug_point_color = color_palette[randi() % color_palette.size()]
	debug_point_color.a = 0.5

func _draw():
	draw_circle(Vector2.ZERO, debug_point_radius, debug_point_color)

	# Draw vision cone
	# drawCone()

	# Draw velocity vector
	# draw_line(Vector2.ZERO, velocity.normalized() * 10, Color.GREEN, 1)

	# Draw flockmate connections
	var lineColor = Color.BLACK
	lineColor.a = 0.5
	for flockMate in flock:
		if flockMate.type != type:
			continue

		draw_line(Vector2.ZERO, flockMate.global_position - global_position, debug_point_color, 1)

func drawCone():
	var points: Array = []
	var direction_angle = atan2(velocity.y, velocity.x)
	var start_angle = direction_angle - deg_to_rad(viewAngle / 2)
	var end_angle = direction_angle + deg_to_rad(viewAngle / 2)
	var step = deg_to_rad(1.0)  # 1 degree step
	var angle = start_angle

	while angle <= end_angle:
		var x = cos(angle) * visualRange
		var y = sin(angle) * visualRange
		points.append(Vector2(x, y))
		angle += step

	# Draw vision boundary lines
	draw_line(Vector2(0, 0), points[0], Color("fff"), 2)
	draw_line(Vector2(0, 0), points[-1], Color("fff"), 2)

	# Draw vision area
	points.insert(0, Vector2(0, 0))
	draw_colored_polygon(points, Color(1, 1, 1, 0.4))

func _on_Area2D_area_entered(area):
	if area.get_parent() is RigidBody2D && area != self and area not in flock && inVisionCone(area.global_position):
		flock.append(area.get_parent())

func _on_Area2D_area_exited(area):
	if area.get_parent() in flock:
		flock.erase(area.get_parent())

func inVisionCone(position):
	var direction_angle = atan2(velocity.y, velocity.x)
	var angle = global_position.direction_to(position).angle()
	var angle_difference = abs(angle - direction_angle)

	return angle_difference < deg_to_rad(viewAngle)

func _physics_process(delta):
	var newVelocity = velocity
	newVelocity += randomVelocity() * randomForce
	newVelocity += separation() * separationForce
	newVelocity += alignment() * alignmentForce
	newVelocity += cohesion() * cohesionForce
	newVelocity += borderForce()

	velocity = velocity.lerp(newVelocity, turnSpeed)
	velocity = velocity.normalized() * min(velocity.length(), speed)

	set_linear_velocity(velocity)

	handle_borders()

	queue_redraw()

func separation():
	var avoidVector = Vector2()

	for flockMate in flock:
		if flockMate.type != type:
			continue

		var flockMatePosition = flockMate.global_position

		var distance = global_position.distance_to(flockMatePosition)
		if (distance < avoidRadius and distance > 0):
			avoidVector -= (flockMatePosition - global_position).normalized() * (avoidRadius / distance * speed)

	return avoidVector

func alignment():
	var numNeighbors = 0
	var alignVector = Vector2()

	for flockMate in flock:
		if flockMate.type != type:
			continue

		if (global_position.distance_to(flockMate.global_position) < visualRange):
			alignVector += flockMate.velocity
			numNeighbors += 1

	if (numNeighbors > 0):
		alignVector /= numNeighbors

	return alignVector

func cohesion():
	var numNeighbors = 0
	var centerVector = Vector2.ZERO

	for flockMate in flock:
		if flockMate.type != type:
			continue

		if (global_position.distance_to(flockMate.global_position) < visualRange):
			centerVector += flockMate.global_position - global_position
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

func handle_borders():
	if global_position.x < viewport_rect.position.x:
		global_position.x = viewport_rect.position.x + viewport_rect.size.x
	elif global_position.x > viewport_rect.position.x + viewport_rect.size.x:
		global_position.x = viewport_rect.position.x

	if global_position.y < viewport_rect.position.y:
		global_position.y = viewport_rect.position.y + viewport_rect.size.y
	elif global_position.y > viewport_rect.position.y + viewport_rect.size.y:
		global_position.y = viewport_rect.position.y

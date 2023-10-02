extends RigidBody2D

@export var maxSpeed = 125
@export var speed = 0
@export var velocity: Vector2

@export var avoidRadius = 30
@export var visualRange = 90
@export var smellRange = 125
@export var turnSpeed = 1

@export var randomForce = 0.02
@export var cohesionForce: = 0.005

@export var viewAngle = 90

@export var color_palette = [
	Color(0.8, 0.0, 0.0, 1.0),  # Red
	Color(0.9, 0.0, 0.0, 1.0),  # Lighter Red
	Color(0.6, 0.0, 0.0, 1.0),  # Darker Red
	Color(0.5, 0.0, 0.0, 1.0),  # Even Darker Red
	Color(0.3, 0.0, 0.0, 1.0),  # Darkest Red
]
@export var type = 'Predator'

var preys = []
var obstacles = []
var viewport_rect

var debug_point_radius = 10.0
var debug_point_color

var area2D: Area2D
var collision_shape: CollisionShape2D

func _ready():
	randomize()

	viewport_rect = get_viewport_rect()

	area2D = get_child(2)
	area2D.connect("area_entered", _on_Area2D_area_entered)
	area2D.connect("area_exited", _on_Area2D_area_exited)

	collision_shape = area2D.get_child(0)
	collision_shape.shape.radius = avoidRadius

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
	for prey in preys:
		if inVisionCone(prey.global_position):
			draw_line(Vector2.ZERO, prey.global_position - global_position, debug_point_color, 1)

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
#inVisionCone(area.global_position)
func _on_Area2D_area_entered(area):
	if area.get_parent() is RigidBody2D && area != self and area not in preys && global_position.distance_to(position) < smellRange:
		preys.append(area.get_parent())
	elif area not in obstacles && "Obstacle" in area.name:
		obstacles.append(area)

func _on_Area2D_area_exited(area):
	if area.get_parent() in preys:
		preys.erase(area.get_parent())
	elif area in obstacles:
		obstacles.erase(area)

func inVisionCone(position):
	var direction_angle = atan2(velocity.y, velocity.x)
	var angle = global_position.direction_to(position).angle()
	var angle_difference = abs(angle - direction_angle)

	var isInAngle = angle_difference < deg_to_rad(viewAngle)

	var isInRange = global_position.distance_to(position) < visualRange

	return isInAngle && isInRange

func _physics_process(delta):
	var newVelocity = velocity

	if preys.size() > 0:
		newVelocity += preyForce()
	else:
		newVelocity += randomVelocity() * randomForce
		newVelocity += cohesion() * cohesionForce

	newVelocity += borderForce()
	newVelocity += obstacleForce()

	velocity = velocity.lerp(newVelocity, turnSpeed)
	velocity = velocity.normalized() * min(velocity.length(), speed)

	set_linear_velocity(velocity)

	handle_borders()

	queue_redraw()

func cohesion():
	var numNeighbors = 0
	var centerVector = Vector2.ZERO

	for prey in preys:
		centerVector += prey.global_position - global_position
		numNeighbors += 1

	if (numNeighbors):
		centerVector /= numNeighbors

	return centerVector

func randomVelocity():
	return Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed

func borderForce():
	var borderVelocity = Vector2()
	var margin = 10

	var distance_to_left_border = global_position.x - (viewport_rect.position.x + margin)
	var distance_to_right_border = (viewport_rect.position.x + viewport_rect.size.x - margin) - global_position.x
	var distance_to_top_border = global_position.y - (viewport_rect.position.y + margin)
	var distance_to_bottom_border = (viewport_rect.position.y + viewport_rect.size.y - margin) - global_position.y

	if distance_to_left_border < avoidRadius:
		borderVelocity.x = ((avoidRadius - distance_to_left_border) / avoidRadius) * speed
	elif distance_to_right_border < avoidRadius:
		borderVelocity.x = (-(avoidRadius - distance_to_right_border) / avoidRadius) * speed

	if distance_to_top_border < avoidRadius:
		borderVelocity.y = ((avoidRadius - distance_to_top_border) / avoidRadius) * speed
	elif distance_to_bottom_border < avoidRadius:
		borderVelocity.y = (-(avoidRadius - distance_to_bottom_border) / avoidRadius) * speed

	return borderVelocity

func obstacleForce():
	var avoidVelocity = Vector2()
	var area2D_position = area2D.global_position

	for area in obstacles:
		var distance = area.global_position.distance_to(area2D_position)
		var direction = (area.global_position - area2D_position).normalized()
		var force = ((avoidRadius - distance) / avoidRadius) * speed

		avoidVelocity += direction * force

	return avoidVelocity

func preyForce():
	var preyVelocity = Vector2()

	for prey in preys:
		if inVisionCone(prey.global_position):
			var direction = (global_position - prey.global_position).normalized()

			preyVelocity -= direction * maxSpeed

	return preyVelocity

func handle_borders():
	if global_position.x < viewport_rect.position.x:
		global_position.x = viewport_rect.position.x + viewport_rect.size.x
	elif global_position.x > viewport_rect.position.x + viewport_rect.size.x:
		global_position.x = viewport_rect.position.x

	if global_position.y < viewport_rect.position.y:
		global_position.y = viewport_rect.position.y + viewport_rect.size.y
	elif global_position.y > viewport_rect.position.y + viewport_rect.size.y:
		global_position.y = viewport_rect.position.y

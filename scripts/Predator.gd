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

var siteArea: Area2D
var siteCollisionShape: CollisionShape2D
var avoidArea: Area2D
var avoidCollisionShape: CollisionShape2D
var bodyArea: Area2D
var bodyCollisionShape: CollisionShape2D

func _ready():
	randomize()

	viewport_rect = get_viewport_rect()

	siteArea = get_child(2)
	siteCollisionShape = siteArea.get_child(0)
	siteCollisionShape.shape.radius = smellRange

	siteArea.connect("body_entered", _on_Area2D_site_body_entered)
	siteArea.connect("body_exited", _on_Area2D_site_body_exited)

	avoidArea = get_child(3)
	avoidCollisionShape = avoidArea.get_child(0)
	avoidCollisionShape.shape.radius = avoidRadius

	avoidArea.connect("body_entered", _on_Area2D_avoid_body_entered)
	avoidArea.connect("body_exited", _on_Area2D_avoid_body_exited)

	bodyArea = get_child(4)

	bodyArea.connect("body_entered", _on_Area2D_boid_body_entered)

	speed = randf_range(maxSpeed / 2, maxSpeed)
	velocity = randomVelocity()

	debug_point_color = color_palette[randi() % color_palette.size()]
	debug_point_color.a = 0.5

func _draw():
	draw_circle(Vector2.ZERO, debug_point_radius, debug_point_color)

	# var smellColor = Color(0.0, 1.0, 0.0, 0.5)
	# draw_circle(Vector2.ZERO, smellRange, smellColor)

	# var avoidColor = Color(1.0, 0.0, 0.0, 0.5)
	# draw_circle(Vector2.ZERO, avoidRadius, avoidColor)

	# Draw vision cone
	# drawCone()

	# Draw velocity vector
	# draw_line(Vector2.ZERO, velocity.normalized() * 10, Color.GREEN, 1)

	# Draw flockmate connections
	var lineColor = Color.BLACK
	lineColor.a = 0.5
	# for prey in preys:
	# 	if inVisionCone(prey.global_position):
	# 		draw_line(Vector2.ZERO, prey.global_position - global_position, debug_point_color, 1)
		# else:
		# 	draw_line(Vector2.ZERO, prey.global_position - global_position, lineColor, 1)

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

func _on_Area2D_boid_body_entered(body):
	body.queue_free()

func _on_Area2D_site_body_entered(body):
	if body != self and body not in preys && body.type != 'Predator':
		preys.append(body)

func _on_Area2D_site_body_exited(body):
	if body in preys:
		preys.erase(body)

func _on_Area2D_avoid_body_entered(body):
	if body not in obstacles && "Obstacle" in body.name:
		obstacles.append(body)

func _on_Area2D_avoid_body_exited(body):
	if body in obstacles:
		obstacles.erase(body)

func inVisionCone(position):
	var direction_angle = atan2(velocity.y, velocity.x)
	var angle = global_position.direction_to(position).angle()
	var angle_difference = abs(angle - direction_angle)

	var isInAngle = angle_difference < deg_to_rad(viewAngle)

	var isInRange = global_position.distance_to(position) < visualRange

	return isInAngle && isInRange

func _physics_process(delta):
	var newVelocity = velocity

	if inAvoidRange():
		newVelocity += borderForce()
		newVelocity += obstacleForce()
	elif preys.size() > 0:
		newVelocity += preyForce()
	else:
		newVelocity += randomVelocity() * randomForce
		newVelocity += cohesion() * cohesionForce

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

func inAvoidRange():
	var margin = 10

	var distance_to_left_border = global_position.x - (viewport_rect.position.x + margin)
	var distance_to_right_border = (viewport_rect.position.x + viewport_rect.size.x - margin) - global_position.x
	var distance_to_top_border = global_position.y - (viewport_rect.position.y + margin)
	var distance_to_bottom_border = (viewport_rect.position.y + viewport_rect.size.y - margin) - global_position.y

	return obstacles.size() > 0 || distance_to_left_border < avoidRadius || distance_to_right_border < avoidRadius || distance_to_top_border < avoidRadius || distance_to_bottom_border < avoidRadius

func borderForce():
	var borderVelocity = Vector2()
	var margin = 10

	var distance_to_left_border = global_position.x - (viewport_rect.position.x + margin)
	var distance_to_right_border = (viewport_rect.position.x + viewport_rect.size.x - margin) - global_position.x
	var distance_to_top_border = global_position.y - (viewport_rect.position.y + margin)
	var distance_to_bottom_border = (viewport_rect.position.y + viewport_rect.size.y - margin) - global_position.y

	if distance_to_left_border < avoidRadius:
		borderVelocity.x = ((avoidRadius - distance_to_left_border) / avoidRadius)
	elif distance_to_right_border < avoidRadius:
		borderVelocity.x = (-(avoidRadius - distance_to_right_border) / avoidRadius)

	if distance_to_top_border < avoidRadius:
		borderVelocity.y = ((avoidRadius - distance_to_top_border) / avoidRadius)
	elif distance_to_bottom_border < avoidRadius:
		borderVelocity.y = (-(avoidRadius - distance_to_bottom_border) / avoidRadius)

	return borderVelocity * maxSpeed

func obstacleForce():
	var avoidVelocity = Vector2()
	var area2D_position = avoidArea.global_position

	for area in obstacles:
		var distance = area.global_position.distance_to(area2D_position)
		var direction = (area.global_position - area2D_position).normalized()
		var force = ((avoidRadius - distance) / avoidRadius) * maxSpeed

		avoidVelocity += direction * force

	return avoidVelocity

func preyForce():
	var closest_prey: Node2D
	var closest_distance: float = 1e10
	var preyVelocity = Vector2()

	for prey in preys:
		var distance = global_position.distance_to(prey.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_prey = prey

	if closest_prey:
		var direction = (closest_prey.global_position - global_position).normalized()
		preyVelocity = direction * maxSpeed

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

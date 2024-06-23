extends RigidBody2D

@export var maxSpeed = 250
@export var speed = 0
@export var velocity: Vector2

@export var avoidRadius = 25
@export var wallRadius = 4
@export var visualRange = 30
@export var turnSpeed = 1

@export var randomForce = 0.05
@export var cohesionForce: = 0.005
@export var alignmentForce: = 0.05
@export var separationForce: = 0.05

@export var attractionForce: = 0.005
@export var attractionPoint: Vector2

@export var viewAngle = 200

@export var fish: Fish

var flock = []
var obstacles = []
var viewport_rect

var debug_point_radius = 4.0
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
	attractionPoint = viewport_rect.position + viewport_rect.size / 2

	siteArea = get_child(2)
	siteCollisionShape = siteArea.get_child(0)
	siteCollisionShape.shape.radius = visualRange

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

func setup():
	var random_color_index = randi() % fish.colors.size()
	var fish_color = fish.colors[random_color_index]
	debug_point_color = Color(fish_color[0], fish_color[1], fish_color[2], 0.5)

func _draw():
	draw_circle(Vector2.ZERO, debug_point_radius, debug_point_color)

	# var sightColor = Color(0.0, 1.0, 0.0, 0.25)
	# draw_circle(Vector2.ZERO, siteCollisionShape.shape.radius, sightColor)

	#var avoidColor = Color(1.0, 0.0, 0.0, 0.25)
	#draw_circle(Vector2.ZERO, avoidCollisionShape.shape.radius, avoidColor)

	# var bodyColor = Color(0.0, 0.0, 1.0, 0.25)
	# draw_circle(Vector2.ZERO, bodyCollisionShape.shape.radius, bodyColor)

	# Draw vision cone
	# drawCone()

	# Draw velocity vector
	# draw_line(Vector2.ZERO, velocity.normalized() * 10, Color.GREEN, 1)

	# draw_line(Vector2.ZERO, cohesion().normalized() * 20, Color.RED, 1)

	# Draw flockmate connections
	#var lineColor = Color.BLACK
	#lineColor.a = 0.5
	#for flockMate in flock:
		#draw_line(Vector2.ZERO, flockMate.global_position - global_position, debug_point_color, 1)

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
	draw_colored_polygon(points, Color(1, 1, 1, 0.2))

func _on_Area2D_boid_body_entered(body):
	body.queue_free()

func _on_Area2D_site_body_entered(body):
	if body != self && inVisionCone(body.global_position) && body not in flock && body.fish.name == fish.name:
		flock.append(body)

func _on_Area2D_site_body_exited(body):
	if body in flock:
		flock.erase(body)

func _on_Area2D_avoid_body_entered(body):
	if body not in obstacles && body.get_child(0) is CollisionPolygon2D:
		obstacles.append(body)

func _on_Area2D_avoid_body_exited(body):
	if body in obstacles:
		obstacles.erase(body)

func calculate_collision_point(area2d, collisionPolygon2d):
	var closest_point = Vector2.ZERO
	var min_distance = INF

	for point in collisionPolygon2d.polygon:
		var global_point = collisionPolygon2d.to_global(point)
		var distance = global_point.distance_to(global_position)

		if distance < min_distance:
			min_distance = distance
			closest_point = global_point

	return closest_point

func inVisionCone(pos):
	var direction_angle = atan2(velocity.y, velocity.x)
	var angle = global_position.direction_to(pos).angle()
	var angle_difference = abs(angle - direction_angle)

	var isInAngle = angle_difference < deg_to_rad(viewAngle)

	return isInAngle

func _physics_process(delta):
	var newVelocity = velocity

	if inAvoidRange():
		newVelocity += borderForce()
		newVelocity += obstacleForce()
	else:
		newVelocity += randomVelocity() * randomForce
		newVelocity += separation() * separationForce
		newVelocity += alignment() * alignmentForce
		newVelocity += cohesion() * cohesionForce
		newVelocity += (attractionPoint - global_position) * attractionForce

	velocity = velocity.lerp(newVelocity, turnSpeed)
	velocity = velocity.normalized() * min(velocity.length(), speed)

	set_linear_velocity(velocity)

	queue_redraw()

func separation():
	var avoidVector = Vector2()

	for flockMate in flock:
		var distance = global_position.distance_to(flockMate.global_position)
		if (distance < avoidRadius and distance > 0):
			avoidVector -= (flockMate.global_position - global_position).normalized() * (avoidRadius / distance * speed)

	return avoidVector

func alignment():
	var numNeighbors = 0
	var alignVector = Vector2()

	for flockMate in flock:
		alignVector += flockMate.velocity
		numNeighbors += 1

	if (numNeighbors > 0):
		alignVector /= numNeighbors

	return alignVector

func cohesion():
	var numNeighbors = 0
	var centerVector = Vector2.ZERO

	for flockMate in flock:
		centerVector += flockMate.global_position - global_position
		numNeighbors += 1

	if (numNeighbors):
		centerVector /= numNeighbors

	return centerVector

func randomVelocity():
	return Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed

func inAvoidRange():
	var distance_to_left_border = global_position.x - (viewport_rect.position.x + 20)
	var distance_to_right_border = (viewport_rect.position.x + viewport_rect.size.x - 5) - global_position.x
	var distance_to_top_border = global_position.y - (viewport_rect.position.y + 20)
	var distance_to_bottom_border = (viewport_rect.position.y + viewport_rect.size.y - 10) - global_position.y

	return obstacles.size() > 0 || distance_to_left_border < wallRadius || distance_to_right_border < wallRadius || distance_to_top_border < wallRadius || distance_to_bottom_border < wallRadius

func borderForce():
	var distance_to_left_border = global_position.x - (viewport_rect.position.x + 20)
	var distance_to_right_border = (viewport_rect.position.x + viewport_rect.size.x - 5) - global_position.x
	var distance_to_top_border = global_position.y - (viewport_rect.position.y + 20)
	var distance_to_bottom_border = (viewport_rect.position.y + viewport_rect.size.y - 10) - global_position.y

	var borderVelocity = Vector2()

	if distance_to_left_border < wallRadius:
		borderVelocity.x = ((wallRadius - distance_to_left_border) / wallRadius)
	elif distance_to_right_border < wallRadius:
		borderVelocity.x = (-(wallRadius - distance_to_right_border) / wallRadius)

	if distance_to_top_border < wallRadius:
		borderVelocity.y = ((wallRadius - distance_to_top_border) / wallRadius)
	elif distance_to_bottom_border < wallRadius:
		borderVelocity.y = (-(wallRadius - distance_to_bottom_border) / wallRadius)

	return borderVelocity * maxSpeed

func obstacleForce():
	var avoidVelocity = Vector2()

	for area in obstacles:
		var collision_polygon_2d = area.get_child(0)

		var result = find_intersection(collision_polygon_2d.polygon)
		var intersection_point = result[0]
		var normal = result[1]

		if !intersection_point || !normal:
			continue

		avoidVelocity += normal * maxSpeed

	return avoidVelocity

func find_intersection(wall_points):
	for i in range(wall_points.size() - 1):
		var P1 = wall_points[i]
		var P2 = wall_points[i + 1]

		var intersection_point = get_intersection(P1, P2)
		if intersection_point != null:
			var unit_normal = calculate_normal(P1, P2, intersection_point, true)
			return [intersection_point, unit_normal]

	return [null, null]

func get_intersection(P1, P2):
	var dx = P2.x - P1.x
	var dy = P2.y - P1.y
	var m_b = calculate_slope_intercept(P1, P2, dx, dy)
	var m = m_b[0]
	var b = m_b[1]

	var intersections = solve_quadratic_for_circle_and_line(m, b, dx, dy, P1)

	for point in intersections:
		if is_point_on_line_segment(P1, P2, point):
			return point

	return null

func calculate_slope_intercept(P1, P2, dx, dy):
	if dx == 0:
		return [null, null]  # Vertical line case
	else:
		var m = dy / dx
		var b = P1.y - m * P1.x
		return [m, b]

func solve_quadratic_for_circle_and_line(m, b, dx, dy, P1):
	var intersections = []
	if m != null:
		# Standard case
		var A = 1 + m * m
		var B = 2 * m * b - 2 * global_position.x - 2 * m * global_position.y
		var C = global_position.x * global_position.x + b * b - 2 * b * global_position.y + global_position.y * global_position.y - wallRadius * wallRadius
		var discriminant = B * B - 4 * A * C
		if discriminant >= 0:
			var root_discriminant = sqrt(discriminant)
			var x1 = (-B + root_discriminant) / (2 * A)
			intersections.append(Vector2(x1, m * x1 + b))
			if discriminant > 0:
				var x2 = (-B - root_discriminant) / (2 * A)
				intersections.append(Vector2(x2, m * x2 + b))
	else:
		# Vertical line case
		var x = P1.x
		var y_range = sqrt(wallRadius * wallRadius - (x - global_position.x) * (x - global_position.x))
		intersections.append(Vector2(x, y_range + global_position.y))
		intersections.append(Vector2(x, -y_range + global_position.y))

	return intersections

func is_point_on_line_segment(P1, P2, point):
	var minX = min(P1.x, P2.x)
	var maxX = max(P1.x, P2.x)
	var minY = min(P1.y, P2.y)
	var maxY = max(P1.y, P2.y)
	return minX <= point.x and point.x <= maxX and minY <= point.y and point.y <= maxY

func calculate_normal(P1, P2, intersection_point, clockwise):
	var dx = P2.x - P1.x
	var dy = P2.y - P1.y
	var normal = Vector2.ZERO
	if clockwise:
		normal = Vector2(dy, -dx)
	else:
		normal = Vector2(-dy, dx)

	# Normalize the normal vector
	var normal_length = normal.length()
	var unit_normal = normal / normal_length
	return unit_normal

# func handle_borders():
# 	if global_position.x < viewport_rect.position.x:
# 		global_position.x = viewport_rect.position.x + viewport_rect.size.x
# 	elif global_position.x > viewport_rect.position.x + viewport_rect.size.x:
# 		global_position.x = viewport_rect.position.x

# 	if global_position.y < viewport_rect.position.y:
# 		global_position.y = viewport_rect.position.y + viewport_rect.size.y
# 	elif global_position.y > viewport_rect.position.y + viewport_rect.size.y:
# 		global_position.y = viewport_rect.position.y

extends RigidBody2D

@export var maxSpeed = 200
@export var speed = 0
@export var velocity: Vector2

@export var avoidRadius = 30
@export var visualRange = 50
@export var turnSpeed = 0.1

@export var randomForce = 0.05
@export var cohesionForce: = 0.005
@export var alignmentForce: = 0.05
@export var separationForce: = 0.05

var maxSize = 20
var minSize = 5

var color_palette = [
	Color(0.0, 0.4, 0.8, 1.0),  # Blue
	Color(0.0, 0.6, 0.9, 1.0),  # Lighter Blue
	Color(0.0, 0.3, 0.6, 1.0),  # Darker Blue
	Color(0.0, 0.2, 0.5, 1.0),  # Even Darker Blue
	Color(0.0, 0.1, 0.3, 1.0),  # Darkest Blue
	Color(1.0, 0.5, 0.0, 1.0),  # Orange
	Color(1.0, 0.6, 0.2, 1.0),  # Lighter Orange
	Color(0.9, 0.4, 0.0, 1.0),  # Darker Orange
	Color(0.8, 0.3, 0.0, 1.0),  # Even Darker Orange
	Color(0.7, 0.2, 0.0, 1.0)   # Darkest Orange
]
var isBlue = false

var tail_positions: Array = []
var max_tail_length = 12
var frame_count = 0
var frame_skip = 2

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

	isBlue = randi() % 2 == 0
	var halfSize = color_palette.size() / 2

	if isBlue:
		modulate = color_palette[randi() % halfSize]
	else:
		modulate = color_palette[halfSize + randi() % halfSize]

func get_interpolated_points(start, end, steps):
	var points = []
	for i in range(steps + 1):
		var t = i / steps
		points.append(start.linear_interpolate(end, t))
	return points

func _draw():
	var velocityMagnitude = velocity.length()
	var size = minSize + ((maxSize - minSize) * (velocityMagnitude / maxSpeed))
	
	var convex_offset = size + (size / 10)
	var concave_offset = size - (size / 10)
	var debug_point_radius = 3.0
	var debug_point_color = Color.WHITE
	debug_point_color.a = 0.5

	# Draw the tail
	for i in range(tail_positions.size() - 1):
		var start = tail_positions[i] - global_position
		var end = tail_positions[i + 1] - global_position
		# draw_circle(start, debug_point_radius, debug_point_color)

	# Calculate front and back offsets based on velocity
	var velocity_norm = velocity.normalized()
	var front_offsets = [velocity_norm.rotated(deg_to_rad(90)) * size, velocity_norm.rotated(deg_to_rad(-90)) * size]
	var back_offsets = [-velocity_norm.rotated(deg_to_rad(90)) * size, -velocity_norm.rotated(deg_to_rad(-90)) * size]

	# Draw front points
	var front_points = []
	for offset in front_offsets:
		var front_point = offset
		front_points.append(front_point)

	# Draw back points, based on the last tail_position if available
	var back_points = []
	if tail_positions.size() > 0:
		var last_tail_position = tail_positions[tail_positions.size() - 1] - global_position
		for offset in back_offsets:
			var back_point = last_tail_position + offset
			back_points.append(back_point)

	# Calculate middle points based on the middle tail position
	var middle_points = []
	if tail_positions.size() > 2:
		var mid_tail_position = tail_positions[tail_positions.size() / 2] - global_position
		var turning_right = global_position.x > tail_positions[tail_positions.size() - 1].x

		var left_offset_magnitude = convex_offset if turning_right else concave_offset
		var right_offset_magnitude = concave_offset if turning_right else convex_offset

		var mid_offsets = [
			velocity_norm.rotated(deg_to_rad(90)) * left_offset_magnitude,
			-velocity_norm.rotated(deg_to_rad(90)) * right_offset_magnitude
		]

		for offset in mid_offsets:
			var middle_point = mid_tail_position + offset
			middle_points.append(middle_point)

		# Store the points
	var polygon_points = []

	if tail_positions.size() > 2:
		polygon_points.append(front_points[0])
		polygon_points.append(middle_points[0])
		polygon_points.append(back_points[1])
		polygon_points.append(back_points[0])
		polygon_points.append(middle_points[1])
		polygon_points.append(front_points[1])
		polygon_points.append(front_points[0])

		# Draw filled polygon
		draw_colored_polygon(polygon_points, debug_point_color)
		draw_polyline(polygon_points, Color.BLACK, 1, true)

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
	velocity += borderForce()

	velocity = velocity.lerp(velocity + alignment() * alignmentForce, turnSpeed)
	velocity = velocity.normalized() * min(velocity.length(), speed)

	set_linear_velocity(velocity)

	# Update tail positions only every `frame_skip` frames
	frame_count += 1
	if frame_count % frame_skip == 0:
		tail_positions.insert(0, global_position)
		if tail_positions.size() > max_tail_length:
			tail_positions.pop_back()

	queue_redraw()

func separation():
	var avoidVector = Vector2()

	for flockMate in flock:
		if flockMate.isBlue != isBlue:
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
		if flockMate.isBlue != isBlue:
			continue

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
		if flockMate.isBlue != isBlue:
			continue

		if (global_position.distance_to(flockMate.global_position) < visualRange):
			centerVector += flockMate.global_position
			numNeighbors += 1

	if (numNeighbors):
		centerVector /= numNeighbors

	return centerVector - global_position

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

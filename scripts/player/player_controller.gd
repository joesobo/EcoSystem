extends RigidBody2D

@export var move_speed: float = 10
@export var jump_force: float = 200
@export var max_slope_angle: float = 45

@onready var sprite: Sprite2D = $Sprite
@onready var ground_check_left: RayCast2D = %GroundCheckLeft
@onready var ground_check_right: RayCast2D = %GroundCheckRight
@onready var wall_check_left: RayCast2D = %WallCheckLeft
@onready var wall_check_right: RayCast2D = %WallCheckRight
@onready var inventory: Control = %Inventory

var is_grounded = false
var is_on_wall = false

func _physics_process(_delta):
	is_grounded = ground_check_left.is_colliding() or ground_check_right.is_colliding()
	is_on_wall = wall_check_left.is_colliding() or wall_check_right.is_colliding()

	var velocity = linear_velocity

	if is_grounded and Input.is_action_pressed("jump"):
		velocity.y = -jump_force
	elif is_grounded:
		velocity.y = 0

	if is_grounded:
		var slope_normal = Vector2.ZERO

		if ground_check_left.is_colliding():
			slope_normal = ground_check_left.get_collision_normal()
		elif ground_check_right.is_colliding():
			slope_normal = ground_check_right.get_collision_normal()
		var slope_angle = rad_to_deg(acos(slope_normal.dot(Vector2.UP)))

		if slope_angle <= max_slope_angle:
			if slope_angle > 0 and (Input.is_action_pressed("move_right") || Input.is_action_pressed("move_left")):
				velocity.y = -move_speed

			# Adjust velocity for slopes
			if Input.is_action_pressed("move_right"):
				velocity.x = move_speed
				sprite.flip_h = true
			elif Input.is_action_pressed("move_left"):
				velocity.x = -move_speed
				sprite.flip_h = false
			else:
				velocity.x = 0
		else:
			velocity.x = 0
	else:
		if Input.is_action_pressed("move_right") and not is_on_wall:
			velocity.x = move_speed
			sprite.flip_h = true
		elif Input.is_action_pressed("move_left") and not is_on_wall:
			velocity.x = -move_speed
			sprite.flip_h = false
		else:
			velocity.x = 0

	linear_velocity = velocity
# 	queue_redraw()

# func _draw():
# 	var start_pos = Vector2(0, 0)

# 	# Define the end position based on the linear velocity
# 	var end_pos = linear_velocity.normalized() * 50

# 	# Draw the line representing the linear velocity
# 	draw_line(start_pos, end_pos, Color.RED, 2)

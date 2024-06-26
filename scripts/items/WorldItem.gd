extends RigidBody2D

@export var item: Item:
	set(value):
		item = value
		update_sprite()
@export var max_speed: float = 250

@onready var sprite = $Sprite2D
@onready var pickup_area = $PickupArea

var instance_id: int

func _ready():
	instance_id = get_instance_id()
	pickup_area.connect('body_entered', Callable(self, '_on_Area2D_body_entered'))

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var current_velocity: Vector2 = state.get_linear_velocity()
	if current_velocity.length() > max_speed:
		current_velocity = current_velocity.normalized() * max_speed
		state.set_linear_velocity(current_velocity)

func update_sprite():
	sprite = $Sprite2D
	sprite.texture = item.icon

func _on_Area2D_body_entered(body):
	if body.is_in_group('player'):
		var inventory = body.inventory

		if inventory.is_room_in_inventory(item):
			item = inventory.pickup_item(item)

			if item.quantity == 0:
				queue_free()
	elif body != self and body.is_in_group('world_item') and body.item.id == item.id:
		# to prevent race condition when merging
		if self.instance_id < body.instance_id:
			merge_with(body)

func merge_with(other):
	var total_quantity = self.item.quantity + other.item.quantity
	if total_quantity <= self.item.max_quantity:
		self.item.quantity = total_quantity
		other.queue_free()
	else:
		self.item.quantity = self.item.max_quantity
		other.item.quantity = total_quantity - self.item.max_quantity

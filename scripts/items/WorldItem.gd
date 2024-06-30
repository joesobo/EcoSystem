extends RigidBody2D

@export var item: Item:
	set(value):
		item = value
		update_sprite()

@onready var sprite = $Sprite2D
@onready var pickup_area = $PickupArea

func _ready():
	pickup_area.connect('body_entered', Callable(self, '_on_Area2D_body_entered'))

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

extends RigidBody2D

@export var item: Item

@onready var sprite = $Sprite2D
@onready var pickup_area = $PickupArea

func _ready():
	# temp code
	item = ItemDefinition.items[0]

	sprite.texture = load("res://sprites/item/%s" % item.icon)
	pickup_area.connect('body_entered', Callable(self, '_on_Area2D_body_entered'))

func _on_Area2D_body_entered(body):
	if body.is_in_group('player'):
		var inventory = body.inventory

		if inventory.is_room_in_inventory():
			inventory.pickup_item(item)
			queue_free()

extends Control

@onready var hotbar = %Hotbar
@onready var extended_inventory = %Extended

var extended: bool = false

func _input(event):
	if event.is_action_pressed("inventory"):
		toggle_extend_inventory()

func toggle_extend_inventory():
	extended = !extended

	if extended:
		extended_inventory.show()
		hotbar.hide()
	else:
		extended_inventory.hide()
		hotbar.show()

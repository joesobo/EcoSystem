extends Panel

var is_dragging = false
var drag_offset = Vector2.ZERO

@export var menu_name: UISingleton.MenuType = UISingleton.MenuType.Storage

@onready var close_button = %Close
@onready var move_button = %Move

func _ready():
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))
	move_button.connect("gui_input", Callable(self, "_on_move_button_pressed"))

func _on_close_button_pressed():
	get_parent().call("close_menu", menu_name)

func _on_move_button_pressed(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = event.position
			else:
				is_dragging = false
	elif event is InputEventMouseMotion && is_dragging:
		global_position += event.position - drag_offset

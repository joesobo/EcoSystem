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
		var new_position = global_position + (event.position - drag_offset)
		ensure_within_viewport(new_position)

func ensure_within_viewport(new_position: Vector2):
	var viewport_rect = get_viewport_rect()

	var move_button_global_pos = new_position + move_button.position

	# Check horizontal boundaries
	if move_button_global_pos.x < viewport_rect.position.x:
		new_position.x = viewport_rect.position.x - move_button.position.x
	elif move_button_global_pos.x + move_button.size.x > viewport_rect.position.x + viewport_rect.size.x:
		new_position.x = viewport_rect.position.x + viewport_rect.size.x - move_button.size.x - move_button.position.x

	# Check vertical boundaries
	if move_button_global_pos.y < viewport_rect.position.y:
		new_position.y = viewport_rect.position.y - move_button.position.y
	elif move_button_global_pos.y + move_button.size.y > viewport_rect.position.y + viewport_rect.size.y:
		new_position.y = viewport_rect.position.y + viewport_rect.size.y - move_button.size.y - move_button.position.y

	# Update the global position with the corrected position
	global_position = new_position

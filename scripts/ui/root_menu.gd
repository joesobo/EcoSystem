extends Panel

var is_dragging = false
var drag_offset = Vector2.ZERO

@export var menu_name: UISingleton.MenuType = UISingleton.MenuType.Storage

@onready var close_button = %Close
@onready var move_button = %Move

func _ready():
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))

func _on_close_button_pressed():
	get_parent().call("close_menu", menu_name)

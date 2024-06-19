extends Control

signal close_button_pressed
signal move_button_pressed(event)

@onready var close_button = %Close
@onready var move_button = %Move
@onready var top_bar = %TopBar

func _ready():
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))
	move_button.connect("gui_input", Callable(self, "_on_move_button_pressed"))
	top_bar.connect("gui_input", Callable(self, "_on_move_button_pressed"))

func _on_close_button_pressed():
	emit_signal("close_button_pressed")

func _on_move_button_pressed(event):
	emit_signal("move_button_pressed", event)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			move_button.set_active()
		else:
			move_button.set_default()

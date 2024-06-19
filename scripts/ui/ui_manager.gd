extends Node

@export var storage_menu_scene = preload("res://scenes/storage_menu.tscn")
@export var breeding_menu_scene = preload("res://scenes/breeding_menu.tscn")

@export var cursor_image = "res://sprites/ui/Cursor.png"
var viewport_size = Vector2(640, 360)

var menu_types = {
	UISingleton.MenuType.Breeding: breeding_menu_scene,
	UISingleton.MenuType.Storage: storage_menu_scene,
}

func _ready():
	update_cursor()
	get_viewport().connect("size_changed", Callable(self, "update_cursor"))

func _input(event):
	if event.is_action_pressed("toggle_breeding"):
		toggle_menu(UISingleton.MenuType.Breeding, 0)

func toggle_menu(menu_name: UISingleton.MenuType, index: int):
	var key = UISingleton.get_menu_key(menu_name, index)
	var menu = UISingleton.get_menu_by_key(key)

	if menu and menu.opened:
		close_menu(key)
	elif menu and !menu.opened:
		open_menu(key)
	else:
		create_menu(menu_name, index)

func create_menu(menu_name: UISingleton.MenuType, index: int):
	var key = UISingleton.get_menu_key(menu_name, index)

	var menu_instance = menu_types[menu_name].instantiate()
	add_child(menu_instance)

	menu_instance.index = index
	menu_instance.global_position = get_viewport().get_mouse_position()
	menu_instance.connect("menu_closed", Callable(self, "close_menu"))

	var new_menu = UISingleton.create_menu(key, menu_instance)
	menu_instance.set_menu(new_menu)

func open_menu(key: String):
	var menu = UISingleton.get_menu_by_key(key)

	menu.opened = true
	menu.instance.global_position = get_viewport().get_mouse_position()
	menu.instance.show()

func close_menu(key: String):
	var menu = UISingleton.get_menu_by_key(key)

	menu.opened = false
	menu.hovered = false
	menu.instance.hide()

func update_cursor():
	var scale_factor = get_viewport().size.x / viewport_size.x

	var image = Image.new()
	image.load(cursor_image)

	var scaled_image = image.duplicate()
	scaled_image.resize(image.get_width() * scale_factor, image.get_height() * scale_factor, Image.INTERPOLATE_NEAREST)

	var image_texture = ImageTexture.create_from_image(scaled_image)

	Input.set_custom_mouse_cursor(image_texture, Input.CursorShape.CURSOR_ARROW)

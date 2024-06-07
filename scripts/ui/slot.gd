extends Area2D

signal slot_pressed(slotIndex)

@onready var itemTexture = %"Item Texture"
@onready var tensCounter = %"Count Texture (Tens)"
@onready var onesCounter = %"Count Texture (Ones)"

var slotIndex: int

func _ready():
	connect("input_event", Callable(self, "_on_input_event"))

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print(slotIndex)
			emit_signal("slot_pressed", slotIndex)

func clear_slot():
	tensCounter.frame = 0
	onesCounter.frame = 0

	tensCounter.hide()
	onesCounter.hide()

	itemTexture.texture = null

func set_slot_texture(item: Item):
	itemTexture.texture = load("res://sprites/item/%s" % item.icon)

func set_slot_quantity(quantity):
	var value = min(max(quantity, 1), 99)

	var tens = (value / 10) % 10
	var ones = value % 10

	tensCounter.frame = tens
	onesCounter.frame = ones

	if value < 10:
		tensCounter.frame = ones
		tensCounter.show()
		onesCounter.hide()
	else:
		# Show both tens and ones digits
		tensCounter.frame = tens
		onesCounter.frame = ones
		tensCounter.show()
		onesCounter.show()

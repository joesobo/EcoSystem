extends Panel

signal slot_pressed(slot_index: int, event: InputEvent)
signal slot_drag_end(slot_index: int, event: InputEvent)

@onready var itemTexture = %"Item Texture"
@onready var tensCounter = %"Count Texture (Tens)"
@onready var onesCounter = %"Count Texture (Ones)"

var slotIndex: int
var item: Item

func _ready():
	connect("gui_input", Callable(self, "_on_gui_input"))

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			emit_signal("slot_pressed", slotIndex, event)
		else:
			emit_signal("slot_drag_end", slotIndex, event)

func clear_slot():
	tensCounter.frame = 0
	onesCounter.frame = 0

	tensCounter.hide()
	onesCounter.hide()

	item = null
	itemTexture.texture = null

func set_item(item: Item):
	self.item = item
	set_slot_texture()
	set_slot_quantity()

func set_slot_texture():
	itemTexture.texture = load("res://sprites/item/%s" % item.icon)

func set_slot_quantity():
	var value = min(max(item.quantity, 1), 99)

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

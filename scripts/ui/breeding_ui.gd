extends Node2D

@onready var score_label = %Label

func update_label(count: int):
	score_label.text = "Total Fish: " + str(count)


extends Control
class_name InstrumentSelectionItem

var item: TInstrumentSelectionItem: set = set_item

@onready var nImage = find_child("Image")

func _ready():
	pass

func _process(delta):
	pass

func set_item(p_item: TInstrumentSelectionItem):
	item = p_item

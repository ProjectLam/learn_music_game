extends Control
class_name InstrumentSelectionItem

var item: TInstrumentSelectionItem: set = set_item

@onready var nImage = find_child("Image")

func _ready():
	pass

func _process(delta):
	var x = get_viewport().get_mouse_position().x / get_viewport_rect().size.x
	var y = get_viewport().get_mouse_position().y / get_viewport_rect().size.y
	var pos = Vector2(x, y)
	
	$Circle.material = $Circle.material.duplicate()
	
	$Circle.material.set_shader_parameter("lighting_point", pos)

func set_item(p_item: TInstrumentSelectionItem):
	item = p_item

func _on_mouse_entered():
	$Circle.material.set_shader_parameter("indicate", true)

func _on_mouse_exited():
	$Circle.material.set_shader_parameter("indicate", false)

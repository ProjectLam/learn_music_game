extends Control

const ISELECT_ITEM = preload("res://scenes/instrument_selection/instrument_selection_item.tscn")

@onready var instrument_selection_box = %InstrumentSelectionBox


func _on_left_btn_pressed():
	instrument_selection_box.go_left()


func _on_right_btn_pressed():
	instrument_selection_box.go_right()


func _on_SelectBtn_pressed():
	instrument_selection_box.select_current()
	get_tree().change_scene_to_file("res://scenes/instrument_menu/instrument_menu.tscn")


func _process(delta):
	var x = get_viewport().get_mouse_position().x / get_viewport_rect().size.x
	var y = get_viewport().get_mouse_position().y / get_viewport_rect().size.y
	var pos = Vector2(x, y)

	$Background/Layer.material.set_shader_parameter("lighting_point", pos)

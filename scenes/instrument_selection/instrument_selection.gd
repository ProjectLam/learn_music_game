extends Control

const ISELECT_ITEM = preload("res://scenes/instrument_selection/instrument_selection_item.tscn")

@onready var instrument_selection_box = %InstrumentSelectionBox

func _ready():
	if get_viewport().gui_get_focus_owner() == null:
		grab_focus()


func _process(delta):
	
	if has_focus():
		if Input.is_action_just_pressed("ui_left"):
			go_right()
		elif Input.is_action_just_pressed("ui_right"):
			go_left()
		if Input.is_action_just_pressed("ui_accept"):
			select_instrument()


func go_left():
	instrument_selection_box.go_left()


func go_right():
	instrument_selection_box.go_right()


func select_instrument():
	instrument_selection_box.select_current()
	get_tree().change_scene_to_file("res://scenes/instrument_menu/instrument_menu.tscn")


func _on_left_btn_pressed():
	go_left()


func _on_right_btn_pressed():
	go_right()


func _on_SelectBtn_pressed():
	select_instrument()

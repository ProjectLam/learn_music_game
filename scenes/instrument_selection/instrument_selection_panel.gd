extends Control

signal instrument_selected(idata: InstrumentData)

@onready var instrument_selection_box = %InstrumentSelectionBox


func _process(delta):
	
	if has_focus():
		if Input.is_action_just_pressed("ui_left"):
			_on_right_button_pressed()
		elif Input.is_action_just_pressed("ui_right"):
			_on_left_button_pressed()
		if Input.is_action_just_pressed("ui_accept"):
			_on_select_button_pressed()


func go_left():
	instrument_selection_box.go_left()


func go_right():
	instrument_selection_box.go_right()


func get_instrument_pressed():
	instrument_selection_box.select_current()

func _on_left_button_pressed():
	go_left()


func _on_right_button_pressed():
	go_right()


func _on_select_button_pressed():
	instrument_selected.emit(instrument_selection_box.get_selected_instrument_data())

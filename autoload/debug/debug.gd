extends CanvasLayer
# This class adds some additional functionality for debugging.
# It will only show up in debug builds. To make sure that's the case when you add more functionality,
# check for is_active().


var _is_active: bool = true
var print_note := false
var print_gui_focus := true


func _ready():
	if !OS.is_debug_build():
		hide()


func print_to_screen(msg: String, print_to_output: bool = false):
	if print_to_output:
		print(msg)
	
	if not is_active():
		return
	
	var debug_print = preload("res://autoload/debug/debug_print.tscn").instantiate()
	debug_print.text = msg
	
	$PrintContainer.add_child(debug_print)


func is_active()->bool:
	return OS.is_debug_build() and _is_active


func _input(event):
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_BACKSLASH:
		if _is_active:
			print_to_screen("Debug overlay OFF")
		_is_active = !_is_active
		if _is_active:
			print_to_screen("Debug overlay ON")

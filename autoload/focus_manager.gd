extends Node

var focus_fallback: Control:
	set = set_focus_fallback
var fallback_counter := 0
var fallback_counter_reset := 3


func _ready() -> void:
	get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)


func _process(_delta) -> void:
	if fallback_counter > 0:
		fallback_counter -= 1
		if fallback_counter == 0:
			var curr_focus := get_viewport().gui_get_focus_owner()
			if not curr_focus and is_instance_valid(focus_fallback):
				print("Changing focus to fallback.")
				focus_fallback.grab_focus()


func _on_gui_focus_changed(control: Control) -> void:
	if Debug.print_gui_focus:
		print("Focus changed to control :", control.get_path())
	fallback_counter = 0
	control.focus_exited.connect(
			func (): _on_focus_exitting(control), CONNECT_ONE_SHOT
	)

func _on_focus_exitting(control: Control) -> void:
	if Debug.print_gui_focus:
		print("Control exitting focus :", control.get_path())
	var curr_scene = get_tree().current_scene
	if not curr_scene or not curr_scene.is_ancestor_of(control):
		var fallback = control.find_prev_valid_focus()
		if is_a_valid_focus_node(fallback):
			focus_fallback = fallback
			return
		
	if curr_scene is Control:
		if is_a_valid_focus_node(curr_scene):
			focus_fallback = curr_scene
			return
		var fallback = curr_scene.find_next_valid_focus()
		if is_a_valid_focus_node(fallback):
			focus_fallback = fallback


func set_focus_fallback(control: Control) -> void:
	fallback_counter = fallback_counter_reset
	if focus_fallback != control:
		if Debug.print_gui_focus and control:
			print("Setting focus fallback to :", control.get_path())
		focus_fallback = control


func is_in_focus_tree():
	var curr_scene = get_tree().current_scene
	var curr_focus = get_viewport().gui_get_focus_owner()
	return not curr_focus or curr_focus == curr_scene or curr_scene.is_ancestor_of(curr_focus)


func is_a_valid_focus_node(node) -> bool:
	return node and node is Control and node.focus_mode == Control.FOCUS_ALL and node.visible

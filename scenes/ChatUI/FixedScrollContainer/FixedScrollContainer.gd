@tool
extends ScrollContainer

@onready var internal_container := $%internalContainer

var view_node_position : Vector2
var view_node : Control

const focus_margin := 10.0

var loading_node_group : String

func _on_scroll_started():
	scrolling = true

func _on_scroll_ended():
	scrolling = false
	
var scrolling := false
var autoscroll_on := true
func _on_scroll_changed():
	var ifob := is_focused_on_bottom()
	if !ifob:
		if is_instance_valid(view_node):
			var ydiff : float =  view_node_position.y - view_node.rect_position.y 
			scroll_vertical = max(scroll_vertical - ydiff, 0)
	else:
		if(!scrolling && autoscroll_on):
			scroll_vertical = 999999
	find_view_node()
	adjusting_bottom_scroll = false
	adjusting_top_scroll = false
	autoscroll_on = true
	if is_instance_valid(view_node):
		view_node_position = view_node.rect_position
	__set_is_focused_on_bottom()

func _is_view_node_valid() -> bool:
	return (is_instance_valid(view_node) && 
	internal_container.is_a_parent_of(view_node) &&
	view_node.visible &&
	!view_node.is_queued_for_deletion())

func find_view_node():
	if _is_view_node_valid():
		if _is_node_in_view(view_node):
			return
		else:
			view_node = _find_view_node()
			if(view_node):
				view_node_position = view_node.rect_position
			adjusting_bottom_scroll = true
			adjusting_top_scroll = true
	else:
		view_node = _find_view_node()
		if(view_node):
			view_node_position = view_node.rect_position
		adjusting_bottom_scroll = true
		adjusting_top_scroll = true

func _is_node_in_view(n : Control) -> bool:
	var ypos := n.position.y - scroll_vertical
	var ybott = ypos + n.rect_size.y
	if ((ypos > 0 && ypos < size.y) ||
		ybott > 0 && ybott < size.y):
		return true
	else:
		return false

func _gui_input(event):
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_WHEEL_UP):
				_tmp_off_autoscroll()

func _tmp_off_autoscroll():
	autoscroll_on = false

func _find_view_node() -> Node:
	for n in internal_container.get_children():
		if n.is_in_group(loading_node_group):
			continue
		if n is Control && n.visible == true && !n.is_queued_for_deletion():
			if _is_node_in_view(n):
				return n
	return null

func get_bottom_margin() -> int:
	return 0

func get_bottom_scroll_value() -> float:
	return internal_container.size.y - size.y


func __set_is_focused_on_bottom() -> void:
	__ifob = get_bottom_scroll_value() - scroll_vertical <= focus_margin

var __ifob := true

func is_focused_on_bottom() -> bool:
	return __ifob

var adjusting_bottom_scroll := false
var adjusting_top_scroll := false

const scroll_script := preload("vscroll.gd")
func _ready():
	find_view_node()
	get_v_scroll_bar().set_script(scroll_script)
	assert(get_v_scroll_bar().connect("changed", _on_scroll_changed) == OK)
	assert(connect("scroll_started", _on_scroll_started) == OK)
	assert(connect("scroll_ended", _on_scroll_ended) == OK)
	assert(get_v_scroll_bar().connect("scroll_started", _on_scroll_started) == OK)
	assert(get_v_scroll_bar().connect("scroll_ended", _on_scroll_ended) == OK)

@tool
extends PanelContainer
class_name GoomContainer

signal global_item_rect_changed()

enum Types {
	SINGLE,
	HBOX,
}

@export var parent_container : String = ""
@export var target_id : String = ""

@export var type : Types = Types.SINGLE

@onready var prev_grect : Rect2 = get_global_rect()

# TODO : change this in future.
# currently godot does not support String for export_enum.
#@export_enum("single","hbox") var type : String = "single"

func get_type_string():
	match(type):
		Types.SINGLE:
			return "single"
		Types.HBOX:
			return "hbox"
		_:
			return "signle"

func get_parent_container() -> String:
	if parent_container != "":
		return parent_container
	elif get_parent() is GoomContainer:
		return get_parent().target_id
	else:
		return ""

func _process(_delta):
	var nr : Rect2 = get_global_rect()
	if nr != prev_grect:
		# TODO : check if this needs to be done in internal_process instead.
		emit_signal("global_item_rect_changed")
	prev_grect = nr
		

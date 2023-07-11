@tool
extends Node3D

@export var string_index: int = 0:
	set = set_string_index

@export var x_offset: float = 0.0:
	set = set_x_offset

@export_range(0.0,1.0) var pointer_alpha: float = 0.5:
	set = set_pointer_alpha

@onready var q = $Q
@onready var a = $A
@onready var z = $Z
@onready var q_pointer = $QPointer
@onready var a_pointer = $APointer
@onready var z_pointer = $ZPointer

@onready var q_string_pos = $QStringPos
@onready var a_string_pos = $AStringPos
@onready var z_string_pos = $ZStringPos

@onready var strings = %Strings


func _ready():
	refresh()


func refresh():
	if not is_inside_tree():
		return
	
	if not is_instance_valid(strings):
		return
	
	var z_pos: Vector3 = strings.get_string_global_position(string_index) + Vector3(x_offset, 0, 0)
	var a_pos: Vector3 = strings.get_string_global_position(string_index + 1) + Vector3(x_offset, 0, 0)
	var q_pos: Vector3 = strings.get_string_global_position(string_index + 2) + Vector3(x_offset, 0, 0)
	
	z_string_pos.global_position = z_pos
	a_string_pos.global_position = a_pos
	q_string_pos.global_position = q_pos
	
	z_pointer.color = strings.get_string_color(string_index) 
	a_pointer.color = strings.get_string_color(string_index + 1)
	q_pointer.color = strings.get_string_color(string_index + 2)
	z_pointer.color.a = pointer_alpha
	a_pointer.color.a = pointer_alpha
	q_pointer.color.a = pointer_alpha
	
#	q.position.y = string_offset + (string_count - string_index)*string_spacing
#	a.position.y = q.position.y - string_spacing
#	z.position.y = a.position.y - string_spacing


func set_string_index(value: int) -> void:
	if string_index != value:
		string_index = value
		refresh()


func set_x_offset(value: float) -> void:
	if x_offset != value:
		x_offset = value
		refresh()


func set_pointer_alpha(value: float) -> void:
	if pointer_alpha != value:
		pointer_alpha = value
		refresh()

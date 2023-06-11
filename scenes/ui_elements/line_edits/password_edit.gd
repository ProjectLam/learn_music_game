@tool
extends MarginContainer

@onready var line_edit = %LineEdit

@export var alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT:
	set = set_alignment
@export var placeholder_text: String:
	set = set_placeholder_text

var text: String:
	get = get_text,
	set = set_text


func _ready():
	line_edit.text = text
	line_edit.placeholder_text = placeholder_text
	line_edit.alignment = alignment


func get_text() -> String:
	if is_instance_valid(line_edit):
		return line_edit.text
	else:
		return ""


func _on_timer_timeout():
	pass # Replace with function body.


func _on_hide_unhide_button_toggled(button_pressed):
	if is_instance_valid(line_edit):
		line_edit.secret = not button_pressed


func set_placeholder_text(value: String) -> void:
	if placeholder_text != value:
		placeholder_text = value
		if is_instance_valid(line_edit):
			line_edit.placeholder_text = placeholder_text


func set_alignment(value: HorizontalAlignment) -> void:
	if alignment != value:
		alignment = value
		if is_instance_valid(line_edit):
			line_edit.alignment = alignment


func set_text(value: String) -> void:
	if is_instance_valid(line_edit):
		if line_edit.text != value:
			line_edit.text = value

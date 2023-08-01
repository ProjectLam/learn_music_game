@tool
extends PanelContainer

@onready var string_label = %StringLabel
@onready var string_panel = %StringPanel
@onready var note_containter = %NoteContainter

@export var string_color := Color.LIGHT_SEA_GREEN:
	set = set_string_color
@export var string_text := "AA":
	set = set_string_text
@export_range(1.0,20.0) var time_length = 8.0:
	set = set_time_length
@export var chromatic := 0

func _ready():
	
	refresh()
	

func refresh():
	if not is_inside_tree():
		return
	
	string_panel["theme_override_styles/panel"]["bg_color"] = string_color
	string_label.text = string_text
	if Engine.is_editor_hint():
		return
	
	note_containter.time_length = time_length


func set_string_color(value: Color) -> void:
	if string_color != value:
		string_color = value
		refresh()


func set_string_text(value: String) -> void:
	if string_text != value:
		string_text = value
		refresh()


func set_time_length(value: float) -> void:
	if time_length != value:
		time_length = value
		refresh()


func add_note(frequency: float) -> void:
	var idx := NoteFrequency.CHROMATIC.find(frequency)
	if idx < 0:
		push_error("invalid frequency.")
		return
	var octave = (idx + 9)/12
	
	note_containter.add_note(octave, Color.WHITE)

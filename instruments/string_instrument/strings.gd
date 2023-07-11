@tool
extends Node3D

signal changed


@onready var frets = %Frets

@export var string_scene: PackedScene

@export var string_space: float = 2.0:
	set = set_string_space

@export var fret_margin: float = 0.1:
	set = set_fret_margin

@export_range(2,40) var string_count := 2:
	set = set_string_count


@export var string_colors: Array[Color] = []:
	set = set_string_colors


@export var string_positions: PackedFloat32Array = []:
	set = set_string_positions

@export_range(0.0,1.0) var bottom_margin := 0.2:
	set = set_bottom_margin
@export_range(0.0,1.0) var top_margin := 0.2:
	set = set_top_margin

@export var curvature_radius := 6.0:
	set = set_curvature_radius
#@export var curvature_y := 0.5

# sets the string positions automatically
@export var uniform_spacing := true:
	set = set_uniform_spacing


# Watch out for :
# - In the editor resized arrays don't automatically update.
# - When calling array modification functions they don't call set functions.


func _ready():
	refresh()


func set_string_space(value: float) -> void:
	value = max(value, 0)
	if string_space != value:
		string_space = value
		changed.emit()
		refresh()


func set_string_count(value: float) -> void:
	if string_count != value:
		value = max(2, value)
		string_count = value
		string_colors.resize(value)
		string_positions.resize(value)
		
		# force uniform positions if needed:
		string_positions = string_positions
		
		changed.emit()
		refresh()


func set_string_colors(value: Array[Color]) -> void:
	value.resize(string_count)
	string_colors = value
	changed.emit()
	refresh()


func set_string_positions(value) -> void:
	value.resize(string_count)
	if not uniform_spacing:
		string_positions = value
	else:
		var spacing := 1.0/(string_count - 1)
		string_positions.resize(string_count)
		for string_index in string_count:
			string_positions[string_index] = spacing * string_index
	changed.emit()
	refresh()


func get_string_local_position(string_index: int) -> Vector3:
	assert(string_index >= 0 and string_index < string_count)
	var local_y = string_space*string_positions[string_index] + bottom_margin
	var total_y_space = string_space + bottom_margin + top_margin
	var angle = atan2((local_y - total_y_space * 0.5), curvature_radius)
	var local_z = 1.0 - cos(angle)
	return Vector3(0.0, local_y , local_z)


func get_string_global_position(string_index: int) -> Vector3:
	assert(string_index >= 0 and string_index < string_count)
	var gtl = global_position
	gtl += get_string_local_position(string_index)
	
	return gtl


func refresh():
	if not is_inside_tree():
		return
	
	if not string_scene:
		push_error("String Scene not set.")
		return
	# we shouldn't free them here because it interrupts the editor.
#	for c in get_children():
#		c.name = "tmp"
#		c.queue_free()
	for extra in range(get_child_count() - string_count - 1, -1, -1):
		var node = get_child(extra)
		remove_child(node)
		node.free()
	
	
	for missing in range(get_child_count(), string_count):
		var string_node := string_scene.instantiate() as Node3D
		add_child(string_node)
	
	
#	if uniform_spacing:
#		var string_spacing = string_space/string_count
#		var 
		#for string_index in string_count:
		#	string_positions[string_index] = string_spacing*string_index
	
	for string_index in string_count:
		var string_node = get_child(string_index)
		string_node.position = get_string_local_position(string_index)
		string_node.set("color", string_colors[string_index])
		string_node.set("fret_space", frets.fret_space)
		string_node.set("fret_margin", fret_margin)
		
#	for string_index in range(0,string_count):
#		var string_node := string_scene.instantiate() as Node3D
#		string_node.position = get_string_local_position(string_index)
#		string_node.set("color", string_colors[string_index])
#		string_node.set("fret_space", frets.fret_space)
#		string_node.set("fret_margin", fret_margin)
#		add_child(string_node)


func set_bottom_margin(value: float) -> void:
	if bottom_margin != value:
		bottom_margin = value
		refresh()


func set_top_margin(value: float) -> void:
	if top_margin != value:
		top_margin = value
		refresh()


func set_curvature_radius(value: float) -> void:
	if curvature_radius != value:
		curvature_radius = value
		refresh()


func set_fret_margin(value: float) -> void:
	if fret_margin != value:
		fret_margin = value
		refresh()

func _on_frets_changed():
	refresh()


func set_uniform_spacing(value: bool) -> void:
	if uniform_spacing != value:
		uniform_spacing = value
		if uniform_spacing:
			string_positions = []
		refresh()


func get_string_color(index: int) -> Color:
	if index >= string_colors.size():
		return Color.BLACK
	else:
		return string_colors[index]

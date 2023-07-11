@tool
extends Node3D

@export_range(0.0,1.0) var thickness := 0.5:
	set = set_thickness

@export_range(0.0, 2.0) var start_padding := 0.1:
	set = set_start_padding

@export_range(0.0, 2.0) var end_padding := 0.1:
	set = set_end_padding

@export var color := Color.WHITE:
	set = set_color

@export_node_path("Node3D") var start_position: NodePath = "":
	set = set_start_position
@export_node_path("Node3D") var end_position: NodePath = "":
	set = set_end_position
@onready var start_position_node = get_node_or_null(start_position):
	set = set_start_position_node
@onready var end_position_node = get_node_or_null(end_position):
	set = set_end_position_node
@onready var mesh_node = $MeshContainer/MeshNode
@onready var mesh_container = $MeshContainer

var last_start_pos: Vector3
var last_end_pos: Vector3

func _ready():
	visible = true
	mesh_node.visible = true
	call_deferred("refresh")


func _process(delta):
	
	if not is_instance_valid(start_position_node) or not is_instance_valid(end_position_node):
		set_process(false)
		if is_instance_valid(mesh_node):
			mesh_node.visible = false
		return
	
	var new_stpos: Vector3 = start_position_node.global_position
	var new_epos: Vector3 = end_position_node.global_position


	if last_start_pos != new_epos or new_epos != last_end_pos:
		last_start_pos = new_stpos
		last_end_pos = new_epos
		refresh()


func refresh():
	if not is_inside_tree():
		return
	
	if not is_instance_valid(start_position_node):
		start_position_node = get_node_or_null(start_position)
	
	if not is_instance_valid(end_position_node):
		end_position_node = get_node_or_null(end_position)
	
	if not is_instance_valid(start_position_node) or not is_instance_valid(end_position_node):
		set_process(false)
		if is_instance_valid(mesh_node):
			mesh_node.visible = false
		return
	else:
		set_process(true)
		mesh_node.visible = true
	
	last_end_pos = end_position_node.global_position
	last_start_pos = start_position_node.global_position
	var vector: Vector3 = last_end_pos - last_start_pos
	var normal := vector.normalized()
	var length = max(vector.length() - start_padding - end_padding, 0.0)
	var start = last_start_pos + normal*start_padding
	var end = last_end_pos - normal*end_padding
	vector = end - start
	if length == 0.0:
		mesh_node.visible = false
	else:
		mesh_node.visible = true
		var midpoint: Vector3 = (start + end)*0.5
	#	mesh_container.position = midpoint
		mesh_container.look_at_from_position(midpoint, end)
		
		mesh_node.mesh["top_radius"] = thickness
		mesh_node.mesh["bottom_radius"] = thickness
		mesh_node.mesh["height"] = length
		
		mesh_node.material_override["albedo_color"] = color
	


func set_thickness(value: float) -> void:
	if thickness != value:
		thickness = value
		refresh()


func set_start_padding(value: float) -> void:
	if start_padding != value:
		start_padding = value
		refresh()


func set_end_padding(value: float) -> void:
	if end_padding != value:
		end_padding = value
		refresh()


func set_color(value: Color) -> void:
	if color != value:
		color = value
		refresh()


func set_start_position_node(value: Node3D) -> void:
	if start_position_node != value:
		start_position_node = value
		refresh()


func set_end_position_node(value: Node3D) -> void:
	if end_position_node != value:
		end_position_node = value
		refresh()


func set_start_position(value: NodePath) -> void:
	if start_position != value:
		start_position = value
		start_position_node = get_node_or_null(start_position)


func set_end_position(value: NodePath) -> void:
	if end_position != value:
		end_position = value
		end_position_node = get_node_or_null(end_position)

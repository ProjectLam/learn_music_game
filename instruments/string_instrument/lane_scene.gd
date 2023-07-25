@tool
extends Node3D

@onready var mesh = %mesh
@onready var label_3d = %Label3D

@export var fret_spacing: float = 1.5:
	set = set_fret_spacing

@export var lane_length: float = 48:
	set = set_lane_length

@export var text: String:
	set = set_text

const LABEL_LOCATION := 0.05

func _ready():
	refresh()


func refresh():
	if not is_inside_tree():
		return
	
	mesh.mesh["size"].x = fret_spacing
	mesh.mesh["size"].y = lane_length
	mesh.position.z = -lane_length*0.5
	label_3d.position.z = -lane_length*LABEL_LOCATION
	label_3d.text = text

func set_fret_spacing(value: float) -> void:
	if fret_spacing != value:
		fret_spacing = value
		refresh()


func set_lane_length(value: float) -> void:
	if lane_length != value:
		lane_length = value
		refresh()


func set_text(value: String) -> void:
	if text != value:
		text = value
		refresh()

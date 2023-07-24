extends InstrumentNote

const POSITIVE_FEEDBACK_SCENE := preload("res://scenes/performance/instruments/piano_positive_note_feedback_3d.tscn")


@onready var note_tail = $NoteTail
var is_open := false
var open_width := 52.0

func set_color(value):
	$MeshInstance3D.material_override.albedo_color = value
	note_tail.material_override.set_shader_parameter("albedo", Color(value.r, value.g, value.b, 0.5))


func set_end_point(value):
	super.set_end_point(value)
	# for now we disable tails because they aren't fully implemented.
	value.z = 0.0
	
	$DurationTail.scale.z = -value.z
	note_tail.length = -value.z


func _ready():
	$MeshInstance3D.material_override = $MeshInstance3D.material_override.duplicate()
	$OpenString.material_override = $MeshInstance3D.material_override
#	note_tail.material_override = note_tail.material_override.duplicate()
#	$DurationTail/OpenStringTail.material_override = note_tail.material_override


func switch_to_open():
	is_open = true
	$MeshInstance3D.hide()
	note_tail.hide()
	$OpenString.show()
	$OpenString.mesh.height = open_width
	$OpenString.position.x = open_width*0.5
	$DurationTail/OpenStringTail.show()


func set_vibrato():
	note_tail.vibrato = true


func set_slide_pitched(to: float):
	note_tail.slide_type = NoteTail.SlideType.PITCHED
	note_tail.end_x_offset = to


func set_slide_unpitched(to: float):
	note_tail.slide_type = NoteTail.SlideType.UNPITCHED
	note_tail.end_x_offset = to


func render():
	pass
#	note_tail.render()


func positive_feedback() -> void:
	var feedback_node := POSITIVE_FEEDBACK_SCENE.instantiate()
	if is_open:
		feedback_node.width = open_width
	
	note_visuals.add_child(feedback_node)
	var extra_offset := Vector3()
	if is_open:
		extra_offset.x = open_width*0.5
	feedback_node.global_position = global_position + extra_offset

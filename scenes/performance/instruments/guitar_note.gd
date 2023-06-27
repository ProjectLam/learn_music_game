extends InstrumentNote


@onready var note_tail = $NoteTail


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
	note_tail.material_override = note_tail.material_override.duplicate()
	$DurationTail/OpenStringTail.material_override = note_tail.material_override


func switch_to_open():
	$MeshInstance3D.hide()
	note_tail.hide()
	$OpenString.show()
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
	note_tail.render()

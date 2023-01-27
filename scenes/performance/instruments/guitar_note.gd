extends InstrumentNote


@onready var note_tail = $NoteTail


func set_color(value):
	$MeshInstance3D.material_override.albedo_color = value
	$DurationTail/MeshInstance3D.material_override.albedo_color = Color(value.r, value.g, value.b, 0.5)


func set_duration(value):
	duration = value
	$DurationTail.scale.z = value * speed
	note_tail.length = value * speed


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


func set_slide_unpitched():
	note_tail.slide_type = NoteTail.SlideType.UNPITCHED


func render():
	note_tail.render()

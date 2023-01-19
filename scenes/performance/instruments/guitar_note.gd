extends InstrumentNote


func set_color(value):
	$MeshInstance3D.material_override.albedo_color = value
	$DurationTail/MeshInstance3D.material_override.albedo_color = Color(value.r, value.g, value.b, 0.5)


func set_duration(value):
	duration = value
	$DurationTail.scale.z = value * speed


func _ready():
	$MeshInstance3D.material_override = $MeshInstance3D.material_override.duplicate()
	$OpenString.material_override = $MeshInstance3D.material_override
	$DurationTail/MeshInstance3D.material_override = $DurationTail/MeshInstance3D.material_override.duplicate()
	$DurationTail/OpenStringTail.material_override = $DurationTail/MeshInstance3D.material_override


func switch_to_open():
	$MeshInstance3D.hide()
	$DurationTail/MeshInstance3D.hide()
	$OpenString.show()
	$DurationTail/OpenStringTail.show()

extends InstrumentNote


func set_color(value):
	$MeshInstance3D.material_override.albedo_color = value
	$MeshInstance3D.material_override.emission = value
	$DurationTail/MeshInstance3D.material_override.albedo_color = 0.5 * value


func set_duration(value):
	duration = value
	$DurationTail.scale.z = value * speed


func _ready():
	$MeshInstance3D.material_override = $MeshInstance3D.material_override.duplicate()
	$DurationTail/MeshInstance3D.material_override = $DurationTail/MeshInstance3D.material_override.duplicate()

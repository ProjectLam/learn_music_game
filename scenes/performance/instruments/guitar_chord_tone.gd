extends Node3D


var color: Color: set = set_color
var is_open: bool = false


func set_color(new_color: Color):
	color = new_color
	$MeshInstance3D.material_override.albedo_color = new_color
#	$DurationTail/MeshInstance3D.material_override.albedo_color = Color(new_color.r, new_color.g, new_color.b, 0.5)


func _ready():
	$MeshInstance3D.material_override = $MeshInstance3D.material_override.duplicate()
	$OpenString.material_override = $MeshInstance3D.material_override
#	$DurationTail/MeshInstance3D.material_override = $DurationTail/MeshInstance3D.material_override.duplicate()
#	$DurationTail/OpenStringTail.material_override = $DurationTail/MeshInstance3D.material_override


func switch_to_open():
	is_open = true
	$MeshInstance3D.hide()
#	$DurationTail/MeshInstance3D.hide()
	$OpenString.show()
#	$DurationTail/OpenStringTail.show()

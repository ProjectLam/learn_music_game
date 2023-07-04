extends InstrumentNote

const POSITIVE_FEEDBACK_SCENE := preload("res://scenes/performance/instruments/piano_positive_note_feedback_3d.tscn")
const NEGATIVE_FEEDBACK_SCENE := preload("res://scenes/performance/instruments/piano_negative_note_feedback_3d.tscn")


func set_color(value):
	pass
#	$MeshInstance3D.material_override.albedo_color = value
#	$MeshInstance3D.material_override.emission = value
#	$DurationTail/MeshInstance3D.material_override.albedo_color = 0.5 * value


func set_end_point(value):
	super.set_end_point(value)
	$DurationTail.scale.z = -value.z


func _ready():
	$DurationTail.scale.z = -end_point.z
#	$MeshInstance3D.material_override = $MeshInstance3D.material_override.duplicate()
#	$DurationTail/MeshInstance3D.material_override = $DurationTail/MeshInstance3D.material_override.duplicate()
#
#func negative_feedback():
#	if note_visuals:
#		var nnode = NEGATIVE_FEEDBACK_SCENE.instantiate()
#
#		note_visuals.add_child(nnode)
#		nnode.global_position = global_position


#func positive_feedback():
#	if note_visuals:
#		var nnode = POSITIVE_FEEDBACK_SCENE.instantiate()
#
#		note_visuals.add_child(nnode)
#		nnode.global_position = global_position

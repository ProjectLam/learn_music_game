extends Node3D


signal note_started()
signal note_ended()


var speed: float = 10.0
var has_started: bool = false

var color: Color:
	set(value):
		$MeshInstance3D.material_override.albedo_color = value
		$MeshInstance3D.material_override.emission = value
		$DurationTail/MeshInstance3D.material_override.albedo_color = 0.5 * value

var duration: float:
	set(value):
		duration = value
		$DurationTail.scale.z = value * speed


func _ready():
	$MeshInstance3D.material_override = $MeshInstance3D.material_override.duplicate()
	$DurationTail/MeshInstance3D.material_override = $DurationTail/MeshInstance3D.material_override.duplicate()


func _process(delta):
	translate(Vector3.BACK * speed * delta)
	
	if position.z >= 0 and not has_started:
		has_started = true
		emit_signal("note_started")
	
	if position.z > speed * duration:
		emit_signal("note_ended")
		queue_free()

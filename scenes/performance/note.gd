extends Node3D


# This note's index in level.notes[]. Will be used to delete it when the player plays it.
var index: int = -1
var speed: float = 10.0
var is_playing: bool = false


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


func play():
	# The player played this note. Do something pretty.
	is_playing = true


func end(successful: bool):
	# The player played and ended this note. Do something pretty, destroy.
	if successful:
		# Reward player
		pass
	else:
		# Show negative feedback animation/effect
		pass
	queue_free()


func destroy():
	# The player missed this note. Destroy it, maybe play a feedback animation.
	queue_free()

extends Node3D


func _ready():
	$MeshInstance3D.material_override = $MeshInstance3D.material_override.duplicate()
	# Running the animation from code rather than autoplay so we can make sure
	# it plays after the material was duplicated
	$MeshInstance3D/AnimationPlayer.play("grow")

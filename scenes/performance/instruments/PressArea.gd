extends MeshInstance3D

@onready var notes = %Notes

func _ready():
	var st: float = 0
	var ed: float = notes.spawn_distance*(2.0*notes.error_margin/notes.look_ahead)
	var zoff := -(ed + st)*0.5
	
	mesh.center_offset.z = zoff
	mesh.size.y = ed - st
	

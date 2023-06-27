extends MeshInstance3D

@onready var notes = %Notes

func _ready():
	var st: float = 0
	var ed: float = notes.get_audio_delay_spacing()
	var zoff := -(ed + st)*0.5
	
	mesh.center_offset.z = zoff
	mesh.size.y = ed - st
	

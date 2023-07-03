extends MeshInstance3D

@onready var notes = %Notes
@onready var trigger_line = $TriggerLine

func _ready():
	var st: float = 0
	var ed: float = notes.get_audio_delay_spacing()
	var zoff := -(ed + st)*0.5
	
	trigger_line.position.z = zoff
	
	mesh.center_offset.z = zoff
	mesh.size.y = ed - st
	

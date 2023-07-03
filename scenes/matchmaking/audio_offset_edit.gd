extends LineEdit



func _ready():
	text = str(SessionVariables.custom_audio_offset)


func _exit_tree():
	SessionVariables.custom_audio_offset = text.to_float()

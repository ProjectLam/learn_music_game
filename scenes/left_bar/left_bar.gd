@tool

extends PanelContainer

func _ready():
	pass

func _process(delta):
	pass

func _on_LoginBtn_pressed() -> void:
	GDialogs.open_single(GLoginDialog)

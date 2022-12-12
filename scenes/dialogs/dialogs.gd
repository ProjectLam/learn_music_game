extends Control

var DIALOGS = [GLoginDialog, GRegisterDialog]


func _ready():
	pass


func _process(delta):
	pass


func open_single(dialog) -> void:
	for other in DIALOGS:
		if other != dialog:
			other.close()

	dialog.open()

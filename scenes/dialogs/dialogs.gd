extends Control

#var DIALOGS = [
#	GLoginDialog,
#	GRegisterDialog
#]

const POPUP_SCENE := preload("res://scenes/dialogs/popup_dialog/popup_dialog.tscn")

@onready var ui_node = %UI
@onready var connection_failed_dialog = %ConnectionFailedDialog
@onready var file_offline_dialog = %FileOfflineDialog
@onready var login_dialog = %LoginDialog
@onready var register_dialog = %RegisterDialog
@onready var login_failed_dialog = %LoginFailedDialog


func _ready():
	pass


func _process(_delta):
	pass


func _on_file_offline_dialog_option_selected(params : Dictionary) -> void:
	file_offline_dialog.close()


func _on_register_dialog_option_selected(params : Dictionary):
	var opt = params.get("option")
	if opt == PopupBase.OPTION_CLOSE:
		register_dialog.close()


func _on_login_dialog_option_selected(params : Dictionary):
	var opt = params.get("option")
	if opt == PopupBase.OPTION_CLOSE:
		login_dialog.close()


func _on_connection_failed_dialog_option_selected(params : Dictionary):
	connection_failed_dialog.close()


func _on_login_failed_dialog_option_selected(params : Dictionary):
	login_failed_dialog.close()


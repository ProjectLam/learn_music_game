@tool

extends PanelContainer

var _js_enabled = Engine.has_singleton("JavaScriptBridge") && OS.get_name() == 'Web'

func _ready():
	pass

func _process(delta):
	pass

func _on_LoginBtn_pressed() -> void:
	if _js_enabled:
		GBackend.open_js_login_dialog()
	else:
		GDialogs.open_single(GLoginDialog)

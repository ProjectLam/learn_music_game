@tool

extends PanelContainer


func _ready():
	pass


func _process(delta):
	pass


func _on_logout_button_pressed():
	var current_scene = get_tree().current_scene
	if current_scene.has_method("request_go_back"):
		current_scene.request_go_back()
	elif current_scene.has_method("go_back"):
		current_scene.go_back()
	else:
		await GBackend.logout()
		if (GBackend.is_js_enabled):
			GBackend.open_js_login_dialog()
		else:
			Dialogs.login_dialog.open()


func request_finish() -> bool:
	var curr_scene := get_tree().current_scene
	if curr_scene.has_method("request_finish"):
		return await curr_scene.request_finish()
	else:
		return true


func _on_play_song_button_pressed():
	var finished = await request_finish()
	if finished:
		get_tree().change_scene_to_file("res://scenes/song_selection/song_selection.tscn")


func _on_matchmaking_button_pressed():
	var finished = await request_finish()
	if finished:
		get_tree().change_scene_to_file("res://scenes/matchmaking/matchmaking.tscn")


func _on_settings_button_pressed():
	var finished = await request_finish()
	if finished:
		get_tree().change_scene_to_file("res://scenes/settings/settings.tscn")


func _on_istrument_menu_button_pressed():
	var finished = await request_finish()
	if finished:
		get_tree().change_scene_to_file("res://scenes/instrument_menu/instrument_menu.tscn")

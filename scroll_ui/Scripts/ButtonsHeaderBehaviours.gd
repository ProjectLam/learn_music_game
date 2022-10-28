extends HBoxContainer
func _on_button_home_mouse_entered():
	$Button_Home.custom_minimum_size = Vector2(380.0,custom_minimum_size.y)
func _on_button_home_mouse_exited():
	$Button_Home.custom_minimum_size = Vector2(30.0,custom_minimum_size.y)
#
func _on_button_artist_mouse_entered():
	$Button_Artist.custom_minimum_size = Vector2(380.0,custom_minimum_size.y)
func _on_button_artist_mouse_exited():
	$Button_Artist.custom_minimum_size = Vector2(30.0,custom_minimum_size.y)
#
func _on_button_album_mouse_entered():
	$Button_Album.custom_minimum_size = Vector2(380.0,custom_minimum_size.y)
func _on_button_album_mouse_exited():
	$Button_Album.custom_minimum_size = Vector2(30.0,custom_minimum_size.y)
#
func _on_button_name_mouse_entered():
	$Button_Name.custom_minimum_size = Vector2(380.0,custom_minimum_size.y)
func _on_button_name_mouse_exited():
	$Button_Name.custom_minimum_size = Vector2(30.0,custom_minimum_size.y)

func _on_button_name_button_down():
	var quickArray = $"../../../HBC_Divider/ScrollContainer/VBC_Buttons".get_children()
	quickArray.sort()
	quickArray.clear()

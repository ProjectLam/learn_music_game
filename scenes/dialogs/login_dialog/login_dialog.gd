extends PopupBase

@onready var email_input = %EmailInput
@onready var password_input = %PasswordInput


func _ready():
	super._ready()
	focus_entered.connect(_on_focus_entered)


func _unhandled_input(event):
	if not visible:
		return
	var focus_owner = get_viewport().gui_get_focus_owner()
	if has_focus() or (focus_owner and is_ancestor_of(focus_owner)):
		if event.is_action_pressed("ui_accept", true):
			_on_login_button_pressed()


func create_params(option: String) -> Dictionary:
	return {
		"option": option,
		"email": email_input.text,
		"password": password_input.text,
	}

func _on_login_button_pressed() -> void:
	_on_option_selected(create_params(OPTION_LOGIN))


func _on_forgot_password_button_pressed() -> void:
	pass # Replace with function body.


func _on_facebook_button_pressed() -> void:
	pass # Replace with function body.


func _on_twitter_button_pressed() -> void:
	pass # Replace with function body.


func _on_google_button_pressed() -> void:
	pass # Replace with function body.


func _on_apple_button_pressed() -> void:
	pass # Replace with function body.


func _on_register_button_pressed() -> void:
	_on_option_selected(create_params(OPTION_REGISTER))


func _on_close_button_pressed() -> void:
	if _on_option_selected(create_params(OPTION_CLOSE)):
		close()


func _on_focus_entered():
	var next = find_next_valid_focus()
	if is_ancestor_of(next):
		next.grab_focus()

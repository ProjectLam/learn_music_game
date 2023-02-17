extends PopupBase

@onready var name_input = %NameInput
@onready var surname_input = %SurnameInput
@onready var email_input = %EmailInput
@onready var password_input = %PasswordInput
@onready var password_repeat_input = %PasswordRepeatInput

# TODO: implement button functionalities.
func create_params(option: String) -> Dictionary:
	return {
		"option": option,
		"name": name_input.text,
		"surname": surname_input.text,
		"email": email_input.text,
		"password": password_input.text,
		"password_repeat": password_repeat_input.text,
	}


func _on_register_button_pressed():
	_on_option_selected(create_params(OPTION_REGISTER))


func _on_login_button_pressed():
	_on_option_selected(create_params(OPTION_LOGIN))


func _on_close_button_pressed():
	if _on_option_selected(create_params(OPTION_CLOSE)):
		close()

extends Control

@onready var username_label = %UsernameLabel

var user: User:
	set = set_user


func _ready():
	print_debug("C")
	refresh()
	print_debug("D")


func set_user(value: User) -> void:
	print_debug("VVVV")
	print_debug(user, ", ", value)
	if user != value:
		user = value
		refresh()


func refresh():
	print_debug("rrrrr")
	if not is_inside_tree():
		return
	print_debug("A")
	if not user:
		return 
	print_debug("B")
	username_label.text = user.username

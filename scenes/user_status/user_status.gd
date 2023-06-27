extends Control

@onready var username_label = %UsernameLabel

var user: User:
	set = set_user


func _ready():
	refresh()


func set_user(value: User) -> void:
	if user != value:
		user = value
		refresh()


func refresh():
	if not is_inside_tree():
		return
	if not user:
		return 
	username_label.text = user.username

@tool
extends PanelContainer

var user: User:
	set = set_user

@onready var user_status = %user_status
@onready var even_panel = %EvenPanel
@onready var odd_panel = %OddPanel
@onready var self_panel = %SelfPanel
@onready var host_panel = %HostPanel

var host_color := Color(1.0,0.7,0.7,1.0)
var self_color := Color(0.7,0.7,1.0,1.0)

func _ready():
	refresh()


func refresh():
	if not is_inside_tree():
		return
	
	user_status.user = user
	
	var is_host = MatchManager.is_user_host(user_status.user)
	var is_self = MatchManager.is_user_self(user_status.user)
	
	if is_host:
		even_panel.visible = false
		odd_panel.visible = false
		host_panel.visible = true
		self_panel.visible = false
	elif is_self:
		even_panel.visible = false
		odd_panel.visible = false
		host_panel.visible = false
		self_panel.visible = true
	elif get_index() % 2 == 0:
		even_panel.visible = true
		odd_panel.visible = false
		host_panel.visible = false
		self_panel.visible = false
	else:
		even_panel.visible = false
		odd_panel.visible = true
		host_panel.visible = false
		self_panel.visible = false


func set_user(value: User) -> void:
	if user != value:
		user = value
		refresh()

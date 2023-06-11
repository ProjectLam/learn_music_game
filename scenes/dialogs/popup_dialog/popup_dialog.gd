extends PopupBase

const BUTTON_SSCENE := preload("popup_button.tscn")

@export var options: Array[String] = []
@export var title := "Popup"
@export_multiline var message := "Message":
	set = set_message
@export var focus_close := false
@export var focus_options := false


@onready var v_box = %VBoxContainer
@onready var title_node = %Title
@onready var message_node = %Message
@onready var close_button = %CloseButton


func _ready():
	super._ready()
	focus_entered.connect(_on_focus_entered)
	for opt in options:
		var bt_node := BUTTON_SSCENE.instantiate()
		if focus_options:
			bt_node.focus_mode = FOCUS_ALL
		else:
			bt_node.focus_mode = FOCUS_NONE
		bt_node.text = opt
		bt_node.pressed.connect(func (): _on_option_selected({"option": opt.to_lower().to_snake_case()}))
		v_box.add_child(bt_node)
#
	title_node.text = title
	message_node.text = "[center]%s[/center]" % message
	if focus_close:
		close_button.focus_mode = FOCUS_ALL
	else:
		close_button.focus_mode = FOCUS_NONE


func _on_close_button_pressed():
	_on_option_selected({"option": OPTION_CLOSE})


func _on_focus_entered():
	if focus_close:
		close_button.grab_focus()


func set_message(value):
	if message != value:
		message = value
		if message_node:
			message_node.text = "[center]%s[/center]" % message

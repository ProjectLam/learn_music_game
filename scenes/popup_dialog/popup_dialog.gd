extends PanelContainer

const BUTTON_SSCENE := preload("popup_button.tscn")

signal option_selected(option)

@export var options: Array[String] = []
@export var title := "Popup"
@export var message := "Message"

@onready var v_box = %VBoxContainer
@onready var title_node = %Title
@onready var message_node = %Message
@onready var animation_player = %AnimationPlayer
@onready var click_blocker = %ClickBlocker

var done := false

var instant_spawn := false
var instant_fade := false

func _ready():
	for opt in options:
		var bt_node := BUTTON_SSCENE.instantiate()
		bt_node.text = opt
		bt_node.pressed.connect(func (): _on_option_selected(opt))
		
		v_box.add_child(bt_node)
	
	title_node.text = title
	message_node.text = message
	
	if not instant_spawn:
		animation_player.play("Open")
		await animation_player.animation_finished
	click_blocker.visible = false


func _on_option_selected(opt : String) -> void:
	done = true
	option_selected.emit(opt)
	if not instant_fade:
		animation_player.play("Close")
		await animation_player.animation_finished
	queue_free()

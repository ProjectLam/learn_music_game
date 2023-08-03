extends Control

@onready var help_panel = %HelpPanel

# Called when the node enters the scene tree for the first time.
func _ready():
	help_panel.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_close_button_pressed():
	help_panel.visible = false


func _on_help_button_pressed():
	help_panel.visible = true

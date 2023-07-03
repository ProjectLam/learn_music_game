extends CheckBox

@onready var dev_options = %DevOptions

func _ready():
	toggled.connect(_on_toggled)
	dev_options.visible = button_pressed


func _on_toggled(p_button_pressed: float) -> void:
	dev_options.visible = p_button_pressed

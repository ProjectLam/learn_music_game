extends PanelContainer

signal selected

@onready var button_overlay = %ButtonOverlay


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _on_button_overlay_pressed() -> void:
	emit_signal("selected")


func _on_button_overlay_mouse_entered():
	if FocusManager.is_in_focus_tree():
		button_overlay.grab_focus()




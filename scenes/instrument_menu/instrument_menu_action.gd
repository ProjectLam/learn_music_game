@tool
extends PanelContainer

signal selected

@onready var button_overlay = %ButtonOverlay

@onready var disabled: bool = button_overlay.disabled:
	set = set_disabled

@onready var label = get_node_or_null("%Label")
@onready var icon_node = %Icon

@export var text := "Button":
	set = set_text

@export var icon: Texture2D:
	set = set_icon


func _ready() -> void:
	refresh()


func _process(delta: float) -> void:
	pass


func refresh() -> void:
	if not is_inside_tree():
		return
	
	if is_instance_valid(label):
		label.text = text
	
	icon_node.texture = icon

func _on_button_overlay_pressed() -> void:
	emit_signal("selected")

func _on_button_overlay_mouse_entered():
	if not disabled and FocusManager.is_in_focus_tree():
		button_overlay.grab_focus()


func _on_button_overlay_mouse_exited():
	if button_overlay.has_focus():
		button_overlay.release_focus()


func set_disabled(value: bool) -> void:
	if disabled != value:
		disabled = value
		button_overlay.disabled = disabled
		if disabled:
			if has_focus():
				# TODO : check if release_focus is the right function to call.
				release_focus()
		elif get_global_rect().has_point(get_global_mouse_position()):
			_on_button_overlay_mouse_entered()


func set_text(value: String) -> void:
	if text != value:
		text = value
		refresh()


func set_icon(value: Texture2D) -> void:
	if icon != value:
		icon = value
		refresh()

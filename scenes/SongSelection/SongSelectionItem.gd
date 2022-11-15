extends PanelContainer
class_name SongSelectionItem

signal hold
signal prelisten

@export var item_style_box: StyleBoxFlat
@export var item_style_box__selected: StyleBoxFlat

@export var hold_timeout = 1.3

@onready var nHoldTimer = $HoldTimer

var song: TSong

var is_touched = false
var hold_leave_time = 0

func _ready():
	add_theme_stylebox_override("panel", item_style_box)
	material = material.duplicate()

func _process(delta):
	pass

func _clips_input():
	return true

func select():
	add_theme_stylebox_override("panel", item_style_box__selected)

func deselect():
	add_theme_stylebox_override("panel", item_style_box)

func _on_gui_input(event):
	var pos = event.position
	var uv = pos / size
	
	material.set_shader_parameter("indicate", true)
	material.set_shader_parameter("size", size)
	material.set_shader_parameter("indicating_point", uv)
	
	if not (event is InputEventMouseButton):
		return
	
	if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and not is_touched:
		nHoldTimer.stop()
		nHoldTimer.start()
	elif event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		nHoldTimer.stop()

func _on_HoldTimer_timeout():
	nHoldTimer.stop()
	emit_signal("hold", song)

func _on_mouse_exited():
	material.set_shader_parameter("indicate", false)

func _on_PrelistenBtn_pressed():
	emit_signal("prelisten", song)

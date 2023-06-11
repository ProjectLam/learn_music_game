extends Control

@onready var blocking_panel = %BlockingPanel


func _ready():
	
	for c in get_children():
		c.visibility_changed.connect(func (): _on_child_visibility_changed(c))
	refresh_visibilities()

func refresh_visibilities():
	var b := false
	for c in get_children():
		if c.visible:
			b = true
			break
	
	blocking_panel.visible = b


func _on_child_visibility_changed(child: Node):
	refresh_visibilities()


func disable_all() -> void:
	for c in get_children():
		c.set("disabled", true)

extends Control

var blocking := false:
	set = set_blocking

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
	
	blocking = b


func _on_child_visibility_changed(child: Node):
	refresh_visibilities()


func set_blocking(value: bool) -> void:
	if blocking != value:
		blocking = value
		if blocking:
			mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			mouse_filter = Control.MOUSE_FILTER_IGNORE


func disable_all() -> void:
	for c in get_children():
		c.set("disabled", true)

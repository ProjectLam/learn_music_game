extends PanelContainer

@onready var uname_label = %uname_label
@onready var uscore_label = %uscore_label


var is_ready := false :
	get:
		return is_ready


var stats: IngameUser :
	set(new_resource):
		if stats != new_resource:
			if stats && stats.changed.is_connected(_on_stats_changed):
				stats.changed.disconnect(_on_stats_changed)
			stats = new_resource
			if(stats):
				stats.changed.connect(_on_stats_changed)
			if is_ready:
				refresh()


func _ready():
	refresh()
	
	is_ready = true


func refresh():
	if not is_ready:
		return
	if(stats):
		uname_label.text = name
		uscore_label.text = "%d" % stats.score

func _on_stats_changed():
	if not is_ready:
		return
	refresh()

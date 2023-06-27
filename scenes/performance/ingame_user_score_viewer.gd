extends PanelContainer

@onready var uname_label = %uname_label
@onready var uscore_label = %uscore_label


var is_ready := false :
	get:
		return is_ready


var iuser: IngameUser :
	set(new_resource):
		if iuser != new_resource:
			if iuser && iuser.changed.is_connected(_on_iuser_changed):
				iuser.changed.disconnect(_on_iuser_changed)
			iuser = new_resource
			if(iuser):
				iuser.changed.connect(_on_iuser_changed)
			if is_ready:
				refresh()


func _ready():
	refresh()
	
	is_ready = true


func _process(delta):
	refresh()


func refresh():
	if not is_ready:
		return
	if(iuser):
		uname_label.text = iuser.user.username if iuser.user else "Me"
		uscore_label.text = "%d" % iuser.score


func _on_iuser_changed():
	if not is_ready:
		return
	refresh()

extends PanelContainer

@onready var usernamen = %Username
@onready var messagen = %Message


@export var message : Resource : 
	set(msg):
		if msg && message != msg && msg is ChatMessageData:
			if(!Engine.is_editor_hint()):
				if(message):
					message.disconnect("changed",_changed)
					message.disconnect("roles_changed",_roles_changed)
			message = msg
			if(!Engine.is_editor_hint()):
				message.connect("changed",_changed)
				message.connect("roles_changed", _roles_changed)
			refresh()

func _changed():
	if(Engine.is_editor_hint()):
		return
	messagen.text = message.message
	usernamen.text = message.get_id_name()

var is_ready := false
func _ready():
	if(is_ready):
		return
	await ready
	_refresh()
	is_ready = true

func refresh():
	if !is_inside_tree():
		return
	var tree := get_tree()
	if !(tree.is_connected("process_frame", __refresh)):
		assert(tree.connect("process_frame", __refresh, CONNECT_ONE_SHOT) == OK)

func _roles_changed():
	pass

func __refresh():
	if(!is_ready):
		return
	queue_redraw()
	_refresh()

func _refresh():
	pass

extends Control

@onready var connection_status_label = %ConnectionStatusLabel
@onready var file_source_label = %FileSourceLabel

const GBackend := preload("res://scenes/GBackend/GBackend.gd")

var is_ready := false

func _ready():
	is_ready = true
	
	refresh()


func refresh():
	if not is_ready:
		return
	
	var file_src_text := ""
	match owner.file_src_mode:
		GBackend.FILE_SRC_MODE.REMOTE:
			file_src_text = "Remote"
		GBackend.FILE_SRC_MODE.FETCHING:
			file_src_text = "Fetching"
		GBackend.FILE_SRC_MODE.OFFLINE:
			file_src_text = "Offline"
	var cstatus_text := ""
	match owner.connection_status:
		GBackend.CONNECTION_STATUS.DISCONNECTED:
			cstatus_text = "Disconnected"
		GBackend.CONNECTION_STATUS.CONNECTING:
			cstatus_text = "Connecting"
		GBackend.CONNECTION_STATUS.CONNECTED:
			cstatus_text = "Connected"
	
	connection_status_label.text = cstatus_text
	file_source_label.text = file_src_text

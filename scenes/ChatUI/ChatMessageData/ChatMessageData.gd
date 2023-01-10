@tool
extends Resource
class_name ChatMessageData

signal roles_changed
signal send_remove_request
signal removed


@export var idx : int
@export var sender_id : String
@export_multiline var message : String
@export var date : int = 0
@export var roles := {}
var delivered_status := false

func get_id_name():
	return sender_id

func delivered(isd : bool = true):
	delivered_status = isd
	emit_changed()

func remove():
	emit_signal("send_remove_request")

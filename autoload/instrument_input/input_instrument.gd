class_name InputInstrument
extends Node


signal note_started(frequency)
signal note_ended(frequency)

signal activated()
signal deactivated()


var is_active: bool = false

func _ready():
	pass


func _process(delta):
	pass


# Abstract
func get_inputs()->Array:
	return []


func activate():
	if not is_active:
		is_active = true
		set_physics_process(true)
		activated.emit()


func deactivate():
	if is_active:
		is_active = false
		set_physics_process(true)
		deactivated.emit()

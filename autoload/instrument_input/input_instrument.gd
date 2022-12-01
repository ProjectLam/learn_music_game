class_name InputInstrument
extends Node


signal note_started(frequency)
signal note_ended(frequency)

signal activated()
signal deactivated()


var is_active: bool = false


# Abstract
func get_inputs()->Array:
	return []


func activate():
	is_active = true
	activated.emit()


func deactivate():
	is_active = false
	deactivated.emit()

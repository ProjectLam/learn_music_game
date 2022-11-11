class_name InputInstrument
extends Node


signal note_started(frequency)
signal note_ended(frequency)


# Abstract
func get_inputs()->Array:
	return []

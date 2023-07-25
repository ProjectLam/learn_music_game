class_name InputInstrument
extends Node


signal note_started(frequency)
signal note_ended(frequency)

signal fret_started(string, fret)
signal fret_ended(string, fret)

signal activated()
signal deactivated()

enum Modes {
	KEYBOARD,
	FRET,
}

var mode: Modes = Modes.KEYBOARD

var is_active: bool = false

var detection_delay := 0.0

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


func chromatic_index_to_fret(index: int) -> Vector2i:
	# experimental.
	return Vector2i((index - 3)/12,(index - 3)%12)


func get_device_names() -> PackedStringArray:
	return []

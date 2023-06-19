class_name InstrumentNote
extends Node3D


# This note's index in level.notes[]. Will be used to delete it when the player plays it.
var index: int = -1

var instrument_notes
var note_visuals: Node3D

var color: Color: set = set_color
var is_playing: bool = false: set = set_is_playing, get = get_is_playing
var end_point: Vector3:
	set = set_end_point

func end(successful: bool):
	# The player played and ended this note. Do something pretty, destroy.
	if successful:
		positive_feedback()
	else:
		negative_feedback()
	queue_free()


# Abstract, use to update the color if needed
func set_color(value: Color):
	pass


# Abastract
func positive_feedback() -> void:
	pass

# Abstract
func negative_feedback() -> void:
	pass


func set_is_playing(value: bool):
	is_playing = value


func get_is_playing() -> bool:
	return is_playing


func set_end_point(value: Vector3) -> void:
	end_point = value

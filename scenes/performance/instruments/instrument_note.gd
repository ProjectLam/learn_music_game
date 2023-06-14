class_name InstrumentNote
extends Node3D


# This note's index in level.notes[]. Will be used to delete it when the player plays it.
var index: int = -1
var speed: float = 10.0
var is_playing: bool = false: set = set_is_playing, get = get_is_playing
var instrument_notes
var note_visuals: Node3D


var color: Color: set = set_color
var duration: float: set = set_duration


func _process(delta):
	if not is_instance_valid(instrument_notes) or not instrument_notes.get("paused"):
		translate(Vector3.BACK * speed * delta)


func play():
	# The player played this note. Do something pretty.
	is_playing = true


func end(successful: bool):
	# The player played and ended this note. Do something pretty, destroy.
	if successful:
		positive_feedback()
	else:
		negative_feedback()
	queue_free()


func destroy():
	negative_feedback()
	queue_free()


# Abstract, use to update the color if needed
func set_color(value: Color):
	pass


# Abstract, use to update the visuals (like a "tail") to depict duration
func set_duration(value: float):
	pass


func set_is_playing(value: bool):
	is_playing = value


func get_is_playing() -> bool:
	return is_playing


# Abastract
func positive_feedback() -> void:
	pass

# Abstract
func negative_feedback() -> void:
	pass

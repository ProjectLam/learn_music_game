class_name InstrumentNote
extends Node3D


# This note's index in level.notes[]. Will be used to delete it when the player plays it.
var index: int = -1
var speed: float = 10.0
var is_playing: bool = false: set = set_is_playing, get = get_is_playing


var color: Color: set = set_color
var duration: float: set = set_duration


func _process(delta):
#	super.
	translate(Vector3.BACK * speed * delta)


func play():
	# The player played this note. Do something pretty.
	is_playing = true


func end(successful: bool):
	# The player played and ended this note. Do something pretty, destroy.
	if successful:
		# Reward player
		pass
	else:
		# Show negative feedback animation/effect
		pass
	queue_free()


func destroy():
	# The player missed this note. Destroy it, maybe play a feedback animation.
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

class_name PerformanceInstrument
extends Node3D


signal note_started(note_data)
signal note_ended(note_data)

@onready var notes = $Notes

func _ready():
	pass


func _process(_delta):
	pass


# It's safe to call this more than once.
func start_game(song_data: Song):
	if not notes.note_started.is_connected(on_note_started):
		notes.note_started.connect(on_note_started)
	if not notes.note_ended.is_connected(on_note_ended):
		notes.note_ended.connect(on_note_ended)
	
	
	if notes.finished:
		notes.start_game(song_data)


func seek(time: float):
	notes.seek(time)


func on_note_started(note_data):
	note_started.emit(note_data)


func on_note_ended(note_data):
	note_ended.emit(note_data)

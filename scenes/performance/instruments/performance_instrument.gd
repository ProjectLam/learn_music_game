class_name PerformanceInstrument
extends Node3D


signal note_started(note_data)
signal note_ended(note_data)


func start_game(song_data: Song):
	$Notes.note_started.connect(on_note_started)
	$Notes.note_ended.connect(on_note_ended)
	
	$Notes.start_game(song_data)


func on_note_started(note_data):
	note_started.emit(note_data)


func on_note_ended(note_data):
	note_ended.emit(note_data)

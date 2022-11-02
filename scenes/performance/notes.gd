extends Node3D


signal note_started()
signal note_ended()


@export var note_scene: PackedScene
# The colors for the guitar strings, from bottom to top
@export var string_colors: PackedColorArray

# How far back from the world origin notes should be spawned
@export var spawn_distance: float = 248

# How far apart the strings are
@export var string_spacing: float
# How far up from the world origin the first string is
@export var string_offset: float
# How far apart the frets are
@export var fret_spacing: float
# How far to the right from the world origin the first note should hit
@export var fret_offset: float


class Note:
	# 0 = bottom (high E), 5 = top (low E)
	var string_index: int
	# 0 = first fret (how do we handle open notes?)
	var fret_index: int
	# When to play the note, in seconds
	var time: float
	# How long to hold the note
	var duration: float
	
	func _init(_string_index: int, _fret_index: int, _time: float, _duration: float):
		string_index = _string_index
		fret_index = _fret_index
		time = _time
		duration = _duration


var song: Array = [
	Note.new(0, 2, 1, 0.5),
	Note.new(1, 1, 1.5, 1),
	Note.new(4, 0, 2.5, 3)
]

var time: float = 0.0


func _process(delta):
	time += delta
	while song.size() > 0 and song[0].time <= time:
		var note_data = song.pop_front()
		var note = note_scene.instantiate()
		add_child(note)
		note.position = Vector3(
			fret_offset + fret_spacing * note_data.fret_index,
			string_offset + string_spacing * note_data.string_index,
			-spawn_distance
		)
		note.color = string_colors[note_data.string_index]
		note.duration = note_data.duration
		note.note_started.connect(on_note_started.bind(note_data))
		note.note_ended.connect(on_note_ended.bind(note_data))


func on_note_started(note_data: Note):
	print("started note ", note_data)
	note_started.emit()


func on_note_ended(note_data: Note):
	print("ended note", note_data)
	note_ended.emit()

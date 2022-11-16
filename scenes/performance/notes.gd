extends Node3D


signal note_started()
signal note_ended()


@export var note_scene: PackedScene
# The colors for the guitar strings, from bottom to top
@export var string_colors: PackedColorArray

# How far back from the world origin notes should be spawned
@export var spawn_distance: float = 48
@export var note_speed: float = 10.0

# How far apart the strings are
@export var string_spacing: float
# How far up from the world origin the first string is
@export var string_offset: float
# How far apart the frets are
@export var fret_spacing: float
# How far to the right from the world origin the first note should hit
@export var fret_offset: float

var _level_data: Level
var _notes: Array[Note]

var look_ahead: float = spawn_distance / note_speed
var time: float = 0.0


func start_game(level_data: Level):
	_level_data = level_data
	_notes = level_data.notes.duplicate()
	time = 0.0


func _process(delta):
	time += delta
	while _notes.size() > 0 and _notes[0].time <= time + look_ahead:
		var note_data: Note = _notes.pop_front()
		var note = note_scene.instantiate()
		note.speed = note_speed
		add_child(note)
		note.position = Vector3(
			fret_offset + fret_spacing * note_data.fret,
			get_string_y(note_data.string),
			-note_speed * (note_data.time - time)
		)
		note.color = string_colors[note_data.string]
		note.duration = note_data.sustain
		note.note_started.connect(on_note_started.bind(note_data))
		note.note_ended.connect(on_note_ended.bind(note_data))


func get_string_y(string_index):
	# Strings start at index 0, 0 being the low E (top string)
	return string_offset + (5 - string_index) * string_spacing


func on_note_started(note_data: Note):
	print("started note ", note_data)
	note_started.emit()


func on_note_ended(note_data: Note):
	print("ended note", note_data)
	note_ended.emit()

extends Node3D


signal note_started(note_data)
signal note_ended(note_data)


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
# The notes you see on screen
var _notes: Array[Note]
var _spawned_notes: Array[Note]
# Used for tracking player performance
var _performance_notes: Array[Note]
var _performance_note_index: int = 0
# Indices of notes the player is currently playing
var _current_note_indices: Array[int]

var look_ahead: float = spawn_distance / note_speed
var time: float = 0.0

# Notes that have passed by this amount of time will count as missed
var missed_max_error: float = 0.5
# If the player plays but the next note is more than this amount of time out, it will not be counted as played
var early_max_error: float = 0.5


func start_game(level_data: Level):
	_level_data = level_data
	_notes = level_data.notes.duplicate()
	_spawned_notes = []
	_performance_notes = level_data.notes.duplicate()
	_performance_note_index = 0
	time = 0.0
	
	InstrumentInput.note_started.connect(_on_input_note_started)
	InstrumentInput.note_ended.connect(_on_input_note_ended)


func _process(delta):
	time += delta
	while _notes.size() > 0 and _notes[0].time <= time + look_ahead:
		var note_data: Note = _notes.pop_front()
		_spawned_notes.append(note_data)
		var note = note_scene.instantiate()
		note.speed = note_speed
		add_child(note)
		note.position = Vector3(
			fret_offset + fret_spacing * note_data.fret,
			_get_string_y(note_data.string),
			-note_speed * (note_data.time - time)
		)
		note.color = string_colors[note_data.string]
		note.duration = note_data.sustain
		note.index = _spawned_notes.size() - 1
	
	while _performance_notes[_performance_note_index].time + _performance_notes[_performance_note_index].sustain < time - missed_max_error:
		_on_missed_note(_performance_note_index)
		_destroy_note(_performance_note_index)
		_performance_note_index += 1


func _get_string_y(string_index):
	# Strings start at index 0, 0 being the low E (top string)
	return string_offset + (5 - string_index) * string_spacing


func _on_input_note_started(pitch: float):
	# Pitch will already be quantized at this point
	var expected = _performance_notes[_performance_note_index]
	var time_difference = expected.time - time
	
	if time_difference > early_max_error:
		_on_invalid_note()
		# Returning so _performance_note_index isn't incremented
		return
	
	var timing_error = abs(time_difference) / missed_max_error if time_difference < 0 else time_difference / early_max_error
	
	if pitch == expected.get_pitch():
		_on_good_note_start(_performance_note_index, timing_error)
		_current_note_indices.append(_performance_note_index)
		_play_note(_performance_note_index)
		note_started.emit(expected)
	else:
		_on_wrong_pitch(_performance_note_index, timing_error)
		_destroy_note(_performance_note_index)
	
	_performance_note_index += 1


func _on_input_note_ended(pitch: float):
	var expected: Note
	var expected_index: int = -1
	
	for i in _current_note_indices.size():
		var note = _performance_notes[_current_note_indices[i]]
		if note.get_pitch() == pitch:
			expected = note
			expected_index = _current_note_indices[i]
			_current_note_indices.remove_at(i)
			break
	
	if expected_index == -1:
		return
	
	var time_difference = expected.time - time
	var timing_error = abs(time_difference) / missed_max_error if time_difference < 0 else time_difference / early_max_error
	
	_on_good_note_end(expected_index, timing_error)
	_end_note(expected_index, abs(timing_error) < 1)
	note_ended.emit(expected)


func _play_note(index: int):
	for note in get_children():
		if note.index == index:
			note.play()
			break


func _end_note(index: int, successful: bool):
	print("Ending note with index ", index)
	for note in get_children():
		if note.index == index:
			note.end(successful)
			break


func _destroy_note(index: int):
	for note in get_children():
		if note.index == index:
			note.destroy()
			break


################################################################################
# Events triggered by gameplay, implement these for positive/negative effects
################################################################################

func _on_good_note_start(note_index: int, timing_error: float):
	# Timing is never perfect, but gets close. timing_error will be normalized, based on
	# missed_max_error and early_max_error. timing_error can be > 1 when the note is long
	# but was played very late.
	
	print("Good note started with an index of ", note_index, " and a timing error of ", timing_error)


func _on_good_note_end(note_index: int, timing_error: float):
	# Timing is never perfect, but gets close. timing_error will be normalized, based on
	# missed_max_error and early_max_error. timing_error can be > 1 when the note is long
	# and was ended very early or very late.
	# Be mindful that notes with a duration of 0 will never have both a perfect start and perfect end
	
	print("Good note ended with an index of ", note_index, " and a timing error of ", timing_error)


func _on_missed_note(note_index: int):
	# Missed the note at _level_data.notes[note_index]
	
	print("Missed note with an index of ", note_index)


func _on_wrong_pitch(note_index: int, timing_error: float):
	# Good timing, but wrong pitch for the note at _level_data.notes[note_index]
	
	print("Played the wrong pitch but with good timing for a note with an index of ", note_index, " and a timing error of ", timing_error)


func _on_invalid_note():
	# The player played a note, but there's nothing to play
	
	print("Played a note while there's nothing to play")

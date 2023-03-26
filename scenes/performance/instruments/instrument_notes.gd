class_name InstrumentNotes
extends Node3D


signal note_started(note_data)
signal note_ended(note_data)
signal good_note_started(note_index: int, timing_error: float)
signal game_finished


@export var note_scene: PackedScene
@export var chord_scene: PackedScene
# How far back from the world origin notes should be spawned
@export var spawn_distance: float = 48
@export var note_speed: float = 10.0


var _song_data: Song
# The notes you see on screen
#var _notes: Array[Note]
var _spawned_notes: Array[Note]
# Used for tracking player performance
var _performance_notes: Array[Note]
var _performance_note_index: int = 0
# Indices of notes the player is currently playing
var _current_note_indices: Array[int]

var look_ahead: float = spawn_distance / note_speed
var time: float = 0.0
var end_time: float = 0.0
# start of the range of notes that haven't spawned yet.
var spawn_index := 0

# Notes that have passed by this amount of time will count as missed
var missed_max_error: float = 0.5
# If the player plays but the next note is more than this amount of time out, it will not be counted as played
var early_max_error: float = 0.5

var finished := true:
	set = set_finished

var paused := true:
	set = set_paused


func _ready():
	refresh_set_process()


func _process(delta):
	time += delta
	var c = 0
	for note_index in range(spawn_index, _performance_notes.size()):
		c += 1
		var note := _performance_notes[note_index]
		if note.time > (time + look_ahead):
			break
		spawn_index += 1
		_spawned_notes.append(note)
		# This indexing is a bit awkward. Is it even needed?
		if note is Chord:
			spawn_chord(note as Chord, _spawned_notes.size() - 1)
		else:
			spawn_note(note, _spawned_notes.size() - 1)
	
	while _is_missed_note(_performance_note_index):
		_on_missed_note(_performance_note_index)
		_destroy_note(_performance_note_index)
		_performance_note_index += 1
	
#	if _notes.size() == 0 and _performance_notes.size() == _performance_note_index:
	if time > end_time:
		print("game finished!")
		set_process(false)
		game_finished.emit()


func set_finished(value: bool) -> void:
	if finished != value:
		finished = value
		refresh_set_process()


func set_paused(value: bool) -> void:
	if paused != value:
		paused = value
		refresh_set_process()


func refresh_set_process():
	set_process(not paused && not finished)


func start_game(song_data: Song):
	if finished:
		_song_data = song_data
		_performance_notes = song_data.get_notes_and_chords_for_difficulty()
		_spawned_notes = []
	#	_performance_notes = _notes.duplicate()
		_performance_note_index = 0
		time = 0.0
		end_time = _performance_notes.back().time + look_ahead
		
		if not InstrumentInput.note_started.is_connected(
				_on_input_note_started):
			InstrumentInput.note_started.connect(_on_input_note_started)
		if not InstrumentInput.note_ended.is_connected(_on_input_note_ended):
			InstrumentInput.note_ended.connect(_on_input_note_ended)
		finished = false
	paused = false


func seek(seek_time: float) -> void:
	print("Seeking insturment to ", seek_time)
	# TODO : there is a small range for notes to be visible AFTER they have passed
	#  their trigger time. Implement this range to respawn them.
	if abs(time - seek_time) < 0.01:
		return
	clear()
	var prev_time = time
	var prev_spawn_idx = spawn_index
	var prev_note_idx = _performance_note_index
	time = clamp(seek_time, 0, end_time)
	var spawn_note = _performance_notes[spawn_index]
	var perf_note = _performance_notes[_performance_note_index]
	var max_index := _performance_notes.size() - 1
	# TODO : add error margins for undo and skip.
	if time < prev_time:
		# seeking backward. untested.
		while perf_note.time > time:
			# TODO : remove from _spawned_notes.
			_on_undo_note(_performance_note_index)
			if _performance_note_index > 0:
				_performance_note_index -= 1
				perf_note = _performance_notes[_performance_note_index]
			else:
				break
		# Undoing notes is done, now we will move forward and respawn visible notes.
		var visible_begin = _performance_note_index + 1
		var visible_end = visible_begin
		_spawned_notes = _performance_notes.slice(0, visible_begin)
		spawn_note = _performance_notes[visible_begin]
		while spawn_note.time < time + look_ahead:
			# note is in view:
			if visible_end < max_index:
				visible_end += 1
				spawn_note = _performance_notes[visible_end]
			else:
				break
		for index in range(visible_begin, visible_end):
			spawn_note = _performance_notes[index]
			_spawned_notes.append(spawn_note)
			if spawn_note is Chord:
				spawn_chord(spawn_note as Chord, _spawned_notes.size() - 1)
			else:
				spawn_note(spawn_note, _spawned_notes.size() - 1)
			
	elif time > prev_time:
		# seeking forward.
		while perf_note.time < time:
			_on_note_skipped(spawn_index)
			if _performance_note_index <= max_index:
				_performance_note_index += 1
				perf_note = _performance_notes[_performance_note_index]
			else:
				# all notes are skipped.
				return
		_spawned_notes = _performance_notes.slice(0, _performance_note_index)
		var visible_begin = _performance_note_index
		var visible_end = visible_begin
		spawn_note = _performance_notes[visible_end]
		# looking for notes that are in the visible range.
		while spawn_note.time < time + look_ahead:
			if visible_end <= max_index:
				visible_end += 1
				spawn_note = _performance_notes[visible_end]
			else:
				break
		for index in range(visible_begin, visible_end):
			spawn_note = _performance_notes[index]
			_spawned_notes.append(spawn_note)
			if spawn_note is Chord:
				spawn_chord(spawn_note as Chord, _spawned_notes.size() - 1)
			else:
				spawn_note(spawn_note, _spawned_notes.size() - 1)
			


func _on_note_skipped(note_index: int):
	pass


func _is_missed_note(note_index: int):
	if note_index >= _performance_notes.size():
		return false
	
	if _performance_notes[note_index] is Chord:
		# For now let's return the same as when it isn't a chord, but I think this might need different checks
		return _performance_notes[note_index].time + _performance_notes[note_index].sustain < time - missed_max_error
	else:
		return _performance_notes[note_index].time + _performance_notes[note_index].sustain < time - missed_max_error


# Abstract, override in child class
func spawn_note(note_data: Note, note_index: int):
	if Debug.print_note:
		print("Spawning Note [idx=%d,time=%d]" % [note_index, note_data.time])


# Abstract, override in child class
func spawn_chord(chord_data: Chord, note_index: int):
	pass


# Abstract, override in deriving class.
# Clears all spawned notes and chords.
func clear() -> void:
	_spawned_notes.clear()
	spawn_index = 0


func _on_input_note_started(pitch: float):
	# Pitch will already be quantized at this point
	var expected = _performance_notes[_performance_note_index]
	var time_difference = expected.time - time
	
	if time_difference > early_max_error:
		_on_invalid_note()
		# Returning so _performance_note_index isn't incremented
		return
	
	var timing_error = abs(time_difference) / missed_max_error if time_difference < 0 else time_difference / early_max_error
	
	if expected is Chord:
		# This means we're using either MIDI or keyboard input and the notes come in separately
		if expected.has_pitch(pitch):
			# This is a good note
			expected.play_pitch(pitch)
			if expected.num_notes_remaining() == 0:
				_on_good_note_start(_performance_note_index, timing_error)
				_current_note_indices.append(_performance_note_index)
				_play_note(_performance_note_index)
				note_started.emit(expected)
			else:
				_on_wrong_pitch(_performance_note_index, timing_error)
				_destroy_note(_performance_note_index)
	else:
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
	if Debug.print_note:
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
	
	if Debug.print_note:
		print("Good note started with an index of ", note_index, " and a timing error of ", timing_error)
	good_note_started.emit(note_index, timing_error)


func _on_good_note_end(note_index: int, timing_error: float):
	# Timing is never perfect, but gets close. timing_error will be normalized, based on
	# missed_max_error and early_max_error. timing_error can be > 1 when the note is long
	# and was ended very early or very late.
	# Be mindful that notes with a duration of 0 will never have both a perfect start and perfect end
	
	if Debug.print_note:
		print("Good note ended with an index of ", note_index, " and a timing error of ", timing_error)


func _on_missed_note(note_index: int):
	# Missed the note at _level_data.notes[note_index]
	
	if Debug.print_note:
		print("Missed note with an index of ", note_index)


func _on_undo_note(note_index: int):
	# Undoing note bonus and penalties.
	pass


func _on_wrong_pitch(note_index: int, timing_error: float):
	# Good timing, but wrong pitch for the note at _level_data.notes[note_index]
	
	if Debug.print_note:
		print("Played the wrong pitch but with good timing for a note with an index of ", note_index, " and a timing error of ", timing_error)


func _on_invalid_note():
	# The player played a note, but there's nothing to play
	
	if Debug.print_note:
		print("Played a note while there's nothing to play")

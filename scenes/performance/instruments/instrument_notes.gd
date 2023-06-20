class_name InstrumentNotes
extends Node3D

signal note_started(note_data)
signal note_ended(note_data)
signal good_note_started(note_index: int, timing_error: float)
signal song_started
signal song_paused
signal song_end_reached

@export var note_scene: PackedScene
@export var chord_scene: PackedScene
# How far back from the world origin notes should be spawned
@export var spawn_distance: float = 48
@export var note_speed: float = 10.0

@onready var note_visuals: Node3D = get_node_or_null("%NoteVisuals")

var _song_data: Song
# The notes you see on screen
#var _notes: Array[NoteBase]
# Used for tracking player performance
var _performance_notes: Array[NoteBase]
var _performance_note_index: int = -1:
	set(value):
		_performance_note_index = value
		assert(_performance_note_index < 0 or _performance_note_index == _performance_notes.size() or spawned_note_nodes.has(_performance_note_index))

# Indices of notes the player is currently playing
# (pitch : start time)
var _current_pitches := {}
# (pitch : { start: start time, end: end time} )
var _pitch_history := {}

var look_ahead: float = spawn_distance / note_speed
var time: float = 0.0
var end_time: float = 0.0
# start of the range of notes that haven't spawned yet.
var spawn_index := -1:
	set(value):
		spawn_index = value
		assert(spawn_index >= -1)
		

# Notes that have passed by this amount of time will count as missed
# If the player plays but the next note is more than this amount of time out, it will not be counted as played
var error_margin: float = 0.25

var finished := true:
	set = set_finished

var paused := true:
	set = set_paused


# TODO : used to ignore mistakes for destroyed wrong chord.
var last_destroyed_note: NoteBase
var last_expected_failed := false

var spawned_note_nodes := {}

var current_good_notes := {}

func _ready():
	refresh_set_process()


func _process(delta):
	for n in spawned_note_nodes:
		assert(n <= spawn_index)
	
	var prev_time = time
	var next_time = time + delta
	if time < 0.0 and next_time >= 0.0:
		# sign changed.
		time = next_time
		song_started.emit()
	time = next_time
	var end_time = time + look_ahead
	var c = 0
	for note_index in range(spawn_index + 1, _performance_notes.size()):
		c += 1
		var note := _performance_notes[note_index]
		if note.time > (time + look_ahead):
			break
		# This indexing is a bit awkward. Is it even needed?
		if note is Chord:
			spawn_chord(note_index)
		else:
			spawn_note(note_index)
			
	for n in spawned_note_nodes:
		assert(n <= spawn_index)
	
	for index in range(max(_performance_note_index, 0), spawn_index + 1):
		var next_note: NoteBase = _performance_notes[index]
		assert(spawned_note_nodes.has(index))
		if next_note.time < time:
			_end_note(index, false)
			_on_missed_note(index)
			# TODO : later we might implement good start but bad end mechanism. for now we just remove.
			if next_note is Note:
				var pitch: float = next_note.get_pitch()
				_current_pitches.erase(pitch)
				_pitch_history.erase(pitch)
			elif next_note is Chord:
				for pitch in next_note.get_pitches():
					_current_pitches.erase(pitch)
					_pitch_history.erase(pitch)
			
			_performance_note_index = min(index + 1, _performance_notes.size())
		else:
			var snote = spawned_note_nodes.get(index)
			if snote == null:
				push_error("Note does not exist")
				continue
			# TODO : move set clip to the refresh function.
			if snote is Node3D:
				snote.set("clip", (time - next_note.time)/next_note.sustain)
			else:
				for csnote in snote:
					csnote.set("clip", (time - next_note.time)/next_note.sustain)
	
#	if time > end_time:
#		print("game finished!")
#		set_process(false)
#		game_finished.emit()
	
	for n in spawned_note_nodes:
		assert(n <= spawn_index)
	
	refresh_note_nodes()


func refresh_note_nodes():
	for index in spawned_note_nodes:
		var snote = spawned_note_nodes[index]
		var note = _performance_notes[index]
		if snote is Node3D:
			snote.position.z = -get_note_offset(note.time)
		else:
			for csnote in snote:
				csnote.position.z = -get_note_offset(note.time)

func get_note_offset(note_time: float) -> float:
#	return spawn_distance
	return spawn_distance*(note_time - time)/look_ahead


func set_finished(value: bool) -> void:
	if finished != value:
		finished = value
		refresh_set_process()


func set_paused(value: bool) -> void:
	if paused != value:
		paused = value
		if paused:
			song_paused.emit()
		else:
			if time > 0.0:
				song_started.emit()
		refresh_set_process()


func refresh_set_process():
	set_process(not paused && not finished)


func start_game(song_data: Song, delay := 15.0):
	if finished:
		_song_data = song_data
		_performance_notes = song_data.get_notes_and_chords_for_difficulty()
		spawn_index = -1
	#	_performance_notes = _notes.duplicate()
		_performance_note_index = -1
		time = - delay
		end_time = _performance_notes.back().time + look_ahead
		
		if not InstrumentInput.note_started.is_connected(
				_on_input_note_started):
			InstrumentInput.note_started.connect(_on_input_note_started)
		if not InstrumentInput.note_ended.is_connected(_on_input_note_ended):
			InstrumentInput.note_ended.connect(_on_input_note_ended)
		finished = false
	
	if time >= 0.0:
		song_started.emit()
	paused = false


func seek(seek_time: float) -> void:
	print("Seeking insturment to ", seek_time)
	# TODO : there is a small range for notes to be visible AFTER they have passed
	#  their trigger time. Implement this range to respawn them.
	if abs(time - seek_time) < 0.01:
		return
#	clear()
	var prev_time = time
	var prev_spawn_idx = spawn_index
	var prev_note_idx = _performance_note_index
	time = min(seek_time, end_time)
	
	var vnotes_range := get_visible_note_range()
	# destroy all current notes.
	# loop has shide effect, it has to use keys()
	for index in spawned_note_nodes.keys():
		destroy_note(index)
		assert(not spawned_note_nodes.has(index))
	
	# no note spawned.
	spawn_index = max(_performance_note_index - 1, -1)
	
	assert(spawned_note_nodes.is_empty())
	
	# spawn all visible notes.
	for index in range(vnotes_range.x, vnotes_range.y):
		var respawn_note = _performance_notes[index]
		if respawn_note is Note:
			spawn_note(index)
		else:
			spawn_chord(index)
	
	spawn_index = max(vnotes_range.y - 1, -1)
	# undo all early notes that had previously passed
	for index in range(vnotes_range.x, _performance_note_index):
		_on_undo_note(index)
	
	
	# skip all late notes.
	for index in range(max(_performance_note_index, 0), vnotes_range.x):
		_on_note_skipped(index)
	
	if vnotes_range.y != 0:
		_performance_note_index = vnotes_range.x
	else:
		_performance_note_index = -1
	
	if not paused:
		if time < 0.0:
			if prev_time >= 0.0:
				song_paused.emit()
		else:
			song_started.emit()
	


func get_visible_note_range() -> Vector2i:
	if _performance_notes.size() == 0:
		return Vector2i()
		
	
	var begin: int = max(max(min(_performance_note_index, _performance_notes.size() - 1), 0), 0)
	var cnote = _performance_notes[begin]
	if cnote.time < time:
		while true:
			if cnote.time > time:
#				begin -= 1
				break
			
			begin += 1
			if begin == _performance_notes.size():
				return Vector2i(begin, begin)
			
			cnote = _performance_notes[begin]
	else:
		while true:
			if cnote.time <= time:
				begin += 1
				begin = min(begin, _performance_notes.size())
				break
			
			if begin == 0:
				break
			
			begin -= 1
			cnote = _performance_notes[begin]
	
	var end := begin
	cnote = _performance_notes[end]
	var etime = time + look_ahead
	while true:
		if cnote.time >= etime:
			break
		
		end += 1
		
		if end == _performance_notes.size():
			break
		cnote = _performance_notes[end]
	
	return Vector2i(begin, end)


func _on_note_skipped(note_index: int):
	pass


func spawn_note(note_index: int):
#	if Debug.print_note:
#		print("Spawning Note [idx=%d]" % [note_index])
	
	assert(not spawned_note_nodes.has(note_index))
	
	spawn_index = max(note_index, spawn_index)


func spawn_chord(note_index: int):
	if Debug.print_note:
		print("Spawning chord [idx=%d]" % [note_index])
	
	assert(not spawned_note_nodes.has(note_index))
	
	spawn_index = max(note_index, spawn_index)


func _on_input_note_started(pitch: float):
	# Pitch will already be quantized at this point
	
	
	if _current_pitches.has(pitch):
		_on_input_note_ended(pitch)
	
	if _performance_note_index >= _performance_notes.size():
		return
	
	if _performance_note_index < 0:
		return
	
	var expected := _performance_notes[_performance_note_index]
	
	if expected is Note:
		if expected.get_pitch() == pitch:
			_current_pitches[pitch] = time
			var tdiff = expected.time - time - error_margin
			var timing_error = abs(tdiff) / error_margin
			if timing_error < 1.0:
				_on_good_note_start(max(_performance_note_index, 0), timing_error)
	elif expected is Chord:
		var has_all := true
		var good := true
		for epitch in expected.get_pitches():
			if epitch == pitch:
				_current_pitches[pitch] = time
				continue
			var cpitch = _current_pitches.get(epitch)
			
			if cpitch == null:
				has_all = false
				good = false
			
			var st_time = cpitch["start_time"]


func _on_input_note_ended(pitch: float):
	var st_time = _current_pitches.get(pitch)
	if st_time == null:
		return
	
	_current_pitches.erase(pitch)
	_pitch_history.erase(pitch)
	
	if _performance_note_index < 0 or _performance_note_index >= _performance_notes.size():
		_current_pitches.erase(pitch)
		return
	
	var expected: NoteBase = _performance_notes[_performance_note_index]
	
	if expected is Note:
		var expected_pitch = expected.get_pitch()
		if expected_pitch == pitch:
			finalize_note(_performance_note_index, st_time, time)
#		else:
#			wrong_pitch_ended(pitch)
	elif expected is Chord:
		var expected_pitches = expected.get_pitches()
		var includes := {}
		if pitch in expected_pitches:
			var all_included := true
			for epitch in expected_pitches:
				if epitch == pitch:
					continue
				
				var phis = _pitch_history.get(epitch)
				if not phis:
					all_included = false
					break
				else:
					includes[epitch] = phis
			
			if not all_included:
				return
		
		includes[pitch] = { "start_time": st_time, "end_time": time }
		finalize_chord(_performance_note_index, includes)


func _play_note(index: int):
	var snote = spawned_note_nodes.get(index)
	if not snote:
		push_warning("Cannot play non existent note")
		return
	
	if snote is Node3D:
		snote.play()
	else:
		for csnote in snote:
			csnote.play()

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


func _end_note(index: int, successful: bool):
#	if Debug.print_note:
#		print("Ending note with index ", index)
	
	var snote = spawned_note_nodes[index]
	spawned_note_nodes.erase(index)
	
#	if not snote:
#		push_error("Trying to end non existent note.")
	
	if snote is Node3D:
		snote.end(successful)
	else:
		for csnote in snote:
			csnote.end(successful)


func finalize_note(index: int, start_time: float, end_time: float) -> bool:
	var note: Note = _performance_notes[index]
	
	var start_time_difference: float = (note.time - error_margin) - start_time
	var start_timing_error: float = abs(start_time_difference) / error_margin
	
	var end_time_difference: float = (note.time + note.sustain - error_margin) - end_time
	var end_timing_error: float = abs(end_time_difference) / error_margin
	
	var good_note: bool = abs(start_timing_error) < 1
	if good_note:
		_on_good_note_end(index, end_timing_error)
		_end_note(index, good_note)
		_performance_note_index = index + 1
		return true
	else:
		return false
		


func finalize_chord(index: int, includes: Dictionary) -> bool:
	var chord: Chord = _performance_notes[index]
	
	var etime = chord.time + chord.sustain
	
	var good_chord_st := true
	var good_chord_ed := true
	var total_eterr := 0.0
	for pitch in chord.get_pitches():
		var pdata = includes.get(pitch)
		
		if pdata == null:
			# invalid call, entry is missing.
			push_error("Invalid call to finalize_chord, entry is missing.")
			return false
		
		var start_time_diff = chord.time - pdata["start_time"]
		var end_time_diff = etime - pdata["end_time"]
		
		var start_timing_error = abs(start_time_diff) / error_margin
		var end_timing_error = abs(end_time_diff) / error_margin
		
		good_chord_st = good_chord_st and start_timing_error < 1.0
		good_chord_ed = good_chord_ed and end_timing_error < 1.0
		
		total_eterr = max(end_timing_error, total_eterr)
	
	if good_chord_st:
		_on_good_note_end(index, total_eterr)
		_end_note(index, good_chord_st)
		_performance_note_index = index + 1
		return true
	else:
		return false


func destroy_note(index: int) -> void:
	var snote = spawned_note_nodes[index]
	spawned_note_nodes.erase(index)
	
	if snote is Node3D:
		snote.queue_free()
	else: 
		for csnote in snote:
			csnote.queue_free()

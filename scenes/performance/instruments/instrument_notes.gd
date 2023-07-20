class_name InstrumentNotes
extends Node3D

enum DIFFICULTY {
	BASIC_TRIGGER,
	
}

signal note_started(note_data)
signal note_ended(note_data)
signal good_note_started(note_index: int, timing_error: float)
signal song_started
signal song_paused
signal song_end_reached
signal song_changed
signal input_note_started
signal input_note_ended
signal input_fret_started
signal input_fret_ended

@export var note_scene: PackedScene
@export var chord_scene: PackedScene
# How far back from the world origin notes should be spawned
@export var spawn_distance: float = 48
@export var note_speed: float = 10.0

@onready var note_visuals: Node3D = get_node_or_null("%NoteVisuals")
@onready var instrument_data: InstrumentData

# search up to next 10 notes to choose fret for the note.
const FRET_MATCH_DEPTH := 10

var difficulty: DIFFICULTY = DIFFICULTY.BASIC_TRIGGER

var _song_data: Song:
	set = set_song_data


var used_pitches: PackedFloat64Array = []
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
var _active_input_pitches := {}
var _prev_active_input_pitches := {}
var _active_frets := {}
var _prev_active_frets := {}
# (pitch : { start: start time, end: end time} )
var _pitch_history := {}

var look_ahead: float = spawn_distance / note_speed
var time: float = 0.0:
	set = set_time
var end_time: float = 0.0
# start of the range of notes that haven't spawned yet.
var spawn_index := -1:
	set(value):
		spawn_index = value
		assert(spawn_index >= -1)
		

# Notes that have passed by this amount of time will count as missed
# If the player plays but the next note is more than this amount of time out, it will not be counted as played
@export_range(0.05,1.0) var error_margin: float = 0.25
var finished := true:
	set = set_finished

var paused := true:
	set = set_paused


# TODO : used to ignore mistakes for destroyed wrong chord.
var last_destroyed_note: NoteBase
var last_expected_failed := false

var spawned_note_nodes := {}

var _good_note_ends := {}

var custom_audio_offset := 0.0

var _current_frets: Array[Vector2i] = []

func _ready():
	# currently used for development purposes only.
	custom_audio_offset = SessionVariables.custom_audio_offset
	
	refresh_set_process()


func _process(delta):
	for n in spawned_note_nodes:
		assert(n <= spawn_index)
	
	var prev_time = time
	var next_time = time + delta
	time = next_time
	if (prev_time + get_audio_delay()) < 0.0 and (next_time + get_audio_delay()) >= 0.0:
		# sign changed.
		time = next_time
		song_started.emit()
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
	
	for n in spawned_note_nodes:
		assert(n <= spawn_index)
	
	refresh_note_nodes()
	_process_frets(delta)


func _process_frets(delta: float) -> void:
	var cf := _current_frets.duplicate()
	_current_frets.clear()
	
	if instrument_data:
		for chromatic in _active_input_pitches.keys():
			var fret := translate_chromatic_to_fret(chromatic)
			var direct_fret = _active_input_pitches[chromatic]
			var pitch := NoteFrequency.CHROMATIC[chromatic]
			if not _prev_active_input_pitches.has(chromatic):
				# process pitch start
				input_note_started.emit(chromatic)
				if not _active_frets.has(fret):
					_active_frets[fret] = direct_fret
					if InstrumentInput.is_input_direct_fret():
						input_fret_started.emit(direct_fret.x, direct_fret.y)
					else:
						input_fret_started.emit(fret.x, fret.y)
	#				_on_input_fret_started(fret.x, fret.y)
			else:
				# check for fret change.
				if not _active_frets.has(fret):
					for afret in _active_frets.keys():
						var apitch := instrument_data.get_tune(afret.x, afret.y)
						if apitch == pitch:
							var direct_afret = _active_frets[afret]
							_active_frets.erase(afret)
							if InstrumentInput.is_input_direct_fret():
								input_fret_ended.emit(direct_fret.x, direct_fret.y)
							else:
								input_fret_ended.emit(afret.x, afret.y)
					_active_frets[fret] = true
					if InstrumentInput.is_input_direct_fret():
						input_fret_started.emit(direct_fret.x, direct_fret.y)
					else:
						input_fret_started.emit(fret.x, fret.y)
		
		
		for chromatic in _prev_active_input_pitches.keys():
			if not _active_input_pitches.has(chromatic):
				# process end pitch.
	#			var pitch := NoteFrequency.CHROMATIC[chromatic]
				input_note_ended.emit(chromatic)
				
				for afret in _active_frets.keys():
					var direct_fret = _active_frets[afret]
					var achromatic := instrument_data.get_tune(afret.x, afret.y)
					if achromatic == chromatic:
						_active_frets.erase(afret)
						
						if InstrumentInput.is_input_direct_fret():
							input_fret_ended.emit(direct_fret.x, direct_fret.y)
						else:
							input_fret_ended.emit(afret.x, afret.y)
		
	else:
		for chromatic in _active_input_pitches.keys():
			var pitch := NoteFrequency.CHROMATIC[chromatic]
			if not _prev_active_input_pitches.has(chromatic):
				# process pitch start
				input_note_started.emit(chromatic)
		for chromatic in _prev_active_input_pitches.keys():
			if not _active_input_pitches.has(chromatic):
				# process end pitch.
	#			var pitch := NoteFrequency.CHROMATIC[chromatic]
				input_note_ended.emit(chromatic)
	
	_prev_active_input_pitches = _active_input_pitches.duplicate()
#	_active_input_pitches = {}
	
	
#	for note in _current_pitches


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
			if get_audio_time() > 0.0:
				song_started.emit()
		refresh_set_process()


func refresh_set_process():
	set_process(not paused && not finished)


func start_game(song_data: Song, delay := 15.0):
	if finished:
		_song_data = song_data
		spawn_index = -1
		_good_note_ends.clear()
	#	_performance_notes = _notes.duplicate()
		_performance_note_index = -1
		time = - delay
		end_time = _performance_notes.back().time + look_ahead
		
		if not InstrumentInput.note_started.is_connected(
				_on_input_note_started):
			InstrumentInput.note_started.connect(_on_input_note_started)
		if not InstrumentInput.note_ended.is_connected(_on_input_note_ended):
			InstrumentInput.note_ended.connect(_on_input_note_ended)
		if not InstrumentInput.fret_started.is_connected(_on_input_fret_started):
			InstrumentInput.fret_started.connect(_on_input_fret_started)
		if not InstrumentInput.fret_ended.is_connected(_on_input_fret_ended):
			InstrumentInput.fret_ended.connect(_on_input_fret_ended)
		finished = false
	
	if get_audio_time() >= 0.0:
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
		if get_audio_time() < 0.0:
			if (prev_time + get_audio_delay()) >= 0.0:
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


func _on_input_note_started(pitch: float, p_string: int = 0, p_fret: int = 0):
	if not is_processing():
		return
	
	var chromatic = NoteFrequency.CHROMATIC.find(pitch)
	# Pitch will already be quantized at this point
	if chromatic >= 0:
		_active_input_pitches[chromatic] = Vector2i(p_string, p_fret)
	if _current_pitches.has(pitch):
		_on_note_ended(pitch)
	
	
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
	
	if difficulty == DIFFICULTY.BASIC_TRIGGER:
		call_deferred("_on_note_ended", pitch, false)


func _on_input_fret_started(p_string: int, p_fret: int) -> void:
	if not is_processing():
		return
	if instrument_data:
		var pitch = NoteFrequency.CHROMATIC[instrument_data.get_tune(p_string, p_fret)]
		_on_input_note_started(pitch, p_string, p_fret)
		
#	input_fret_started.emit(p_string, p_fret)
	pass


#func _on_input_fret_note_started(p_string: int, p_fret: int) -> void:
#

func _on_input_note_ended(pitch: float) -> void:
	var chromatic := NoteFrequency.CHROMATIC.find(pitch)
	if chromatic >= 0:
		_active_input_pitches.erase(chromatic)
	_on_note_ended(pitch)


func _on_note_ended(pitch: float):
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


func _on_input_fret_ended(p_string: int, p_fret: int) -> void:
	if instrument_data:
		var pitch = NoteFrequency.CHROMATIC[instrument_data.get_tune(p_string, p_fret)]
		_on_input_note_ended(pitch)
#	input_fret_ended.emit(p_string, p_fret)
	pass


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
	_good_note_ends[note_index] = timing_error
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


func set_song_data(value: Song) -> void:
	if _song_data != value:
		_song_data = value
		
		used_pitches.clear()
		_performance_notes = _song_data.get_notes_and_chords_for_difficulty()
		var unotes := {}
		
		for note in _performance_notes:
			if note is Note:
				unotes[note.get_pitch()] = true
			elif note is Chord:
				for pitch in note.get_pitches():
					unotes[pitch] = true
		
		used_pitches = unotes.keys()
		
		song_changed.emit()


func get_audio_time() -> float:
	return time + get_audio_delay()


func set_time(value: float) -> void:
	if time != value:
		time = value
		


func get_audio_delay():
	return error_margin - custom_audio_offset - (_song_data.audio_offset if _song_data else 0.0)


func get_press_area_spacing() -> float:
	return spawn_distance*(2.0*error_margin/look_ahead)


func translate_chromatic_to_fret(chromatic: int) -> Vector2i:
	var pitch := NoteFrequency.CHROMATIC[chromatic]
	if instrument_data == null:
		return Vector2i(0,0)


	for index in range(_performance_note_index, min(_performance_note_index + FRET_MATCH_DEPTH, _performance_notes.size() - 1)):
		var note_data: NoteBase = _performance_notes[index]
		
		if note_data is Note:
			var note_pitch: float = note_data.get_pitch()
			if note_pitch != pitch:
				continue
			
			var mappedsfret = instrument_data.map_string_note(note_data.string, note_data.fret)
			var string = mappedsfret.x
			var fret = mappedsfret.y
			return Vector2i(string, fret)
		elif note_data is Chord:
			var note_frets: Array[int] = note_data.get_frets()
			for string in note_frets.size():
				var fret = note_frets[string]
				if fret == -1:
					continue
				
				var fpitch: float = note_data.get_pitch_for_string(string)
				if fpitch == pitch:
					return Vector2i(string, fret)


	var min_fret := 9999
	var min_sring := -1
	# note was not found. we will choose the lowest distance.
	for string_index in instrument_data.tuning_pitches.size():
		var string_chromatic := instrument_data.tuning_pitches[string_index]
		var fdistance := chromatic - string_chromatic
		if fdistance < 0:
			continue
		
		if fdistance < min_fret:
			min_fret = fdistance
			min_sring = string_index


	if min_sring >= 0:
		assert(instrument_data.get_tune(min_sring, min_fret) == chromatic)
		return Vector2i(min_sring, min_fret)
	else:
		return Vector2i(0,0)

class_name Song


var song_music_file: String
var song_music_buffer: PackedByteArray

# Generic Variant used by song_loader.gd to load the song.
var song_music_file_access = FileAccess

var version: int
var title: String
var arrangement: String
var part: int
var offset: float
var cent_offset: float # TODO: investigate whether this might be an int, if cent refers to tuning
var song_length: float
var song_name_sort: String
var start_beat: float
var average_tempo: float
var tuning: Dictionary
var capo: int
var artist_name: String
var artist_name_sort: String
var album_name: String
var album_name_sort: String
var album_year: int
var album_art: String # TODO: figure out what this weird string is
var crowd_speed: int
var arrangement_properties: Dictionary
var last_conversion_date_time: String # Think this is from the conversion tool. Potentially useful for version tracking?
var phrases: Array[SongPhrase]
var new_linked_diffs: Array[SongNewLinkedDiff]
var phrase_iterations: Array[SongPhraseIteration]
var linked_diffs: Array[Dictionary] # TODO: xml has none of these, figure out what it is
var phrase_properties: Array[Dictionary] # TODO: xml has none of these, figure out what it is
var chord_templates: Array[SongChordTemplate]
var fret_hand_mute_templates: Array[Dictionary] # TODO: xml has none of these, figure out what it is
var ebeats: Array[SongEbeat]
var tonebase: String
var tone_a: String
var tone_b: String
var tone_c: String
var tone_d: String
var tones: Array[SongTone]
var sections: Array[SongSection]
var events: Array[SongEvent]
var transcription_track: SongTranscriptionTrack
var levels: Array[SongLevel]


func get_notes_and_chords_for_difficulty(difficulty: int = -1) -> Array:
	var notes_and_chords: Array = []
	for i in phrase_iterations.size():
		var pi := phrase_iterations[i]
		var end_time: float
		if i < phrase_iterations.size() - 1:
			end_time = phrase_iterations[i + 1].time
		else:
			end_time = INF
		
		var phrase: SongPhrase = phrases[pi.phrase_id]
		
		# Godot's min() returns a float
		var level: int = difficulty if difficulty > -1 and difficulty < phrase.max_difficulty else phrase.max_difficulty
		
		for song_note in levels[level].notes:
			if song_note.time < pi.time or song_note.time > end_time:
				continue
			
			var note := Note.new()
			note.time = song_note.time
			note.link_next = song_note.link_next
			note.accent = song_note.accent
			note.bend = song_note.bend
			note.fret = song_note.fret
			note.hammer_on = song_note.hammer_on
			note.harmonic = song_note.harmonic
			note.hopo = song_note.hopo
			note.ignore = song_note.ignore
			note.left_hand = song_note.left_hand
			note.mute = song_note.mute
			note.palm_mute = song_note.palm_mute
			note.pluck = song_note.pluck
			note.pull_off = song_note.pull_off
			note.slap = song_note.slap
			note.slide_to = song_note.slide_to
			note.string = song_note.string
			note.sustain = song_note.sustain
			note.tremolo = song_note.tremolo
			note.harmonic_pinch = song_note.harmonic_pinch
			note.pick_direction = song_note.pick_direction
			note.right_hand = song_note.right_hand
			note.slide_unpitch_to = song_note.slide_unpitch_to
			note.tap = song_note.tap
			note.vibrato = song_note.vibrato
			
			notes_and_chords.append(note)
		
		for song_note in levels[level].chords:
			if song_note.time < pi.time or song_note.time > end_time:
				continue
			
			var chord_template := chord_templates[song_note.chord_id]
			#@TODO We're not doing anything with chord notes here yet, which are a separate list in XML that only some chords have.
			var chord := Chord.new()
			chord.display_name = chord_template.display_name
			chord.chord_name = chord_template.chord_name
			chord.fret_0 = chord_template.fret_0
			chord.fret_1 = chord_template.fret_1
			chord.fret_2 = chord_template.fret_2
			chord.fret_3 = chord_template.fret_3
			chord.fret_4 = chord_template.fret_4
			chord.fret_5 = chord_template.fret_5
			chord.finger_0 = chord_template.finger_0
			chord.finger_1 = chord_template.finger_1
			chord.finger_2 = chord_template.finger_2
			chord.finger_3 = chord_template.finger_3
			chord.finger_4 = chord_template.finger_4
			chord.finger_5 = chord_template.finger_5
			
			chord.time = song_note.time
			chord.link_next = song_note.link_next
			chord.accent = song_note.accent
			# Up and down seem to be the only options in the songs we have, but we might need to support other "strum" types (plucking comes to mind)
			chord.strum = Chord.Strum.UP if song_note.strum == "up" else Chord.Strum.DOWN
			chord.high_density = song_note.high_density
			chord.fret_hand_mute = song_note.fret_hand_mute
			
			notes_and_chords.append(chord)
	
	notes_and_chords.sort_custom(
		func sort_notes_and_chords(note_a, note_b):
			return note_a.time < note_b.time
	)
	
	return notes_and_chords

func get_identifier() -> String:
	return title

class SongPhrase:
	var disparity: bool
	var ignore: bool
	var max_difficulty: int
	var name: String
	var solo: bool


class SongNewLinkedDiff:
	var level_break: int
	var ratio
	var phrase_count: int
	var nld_phrases: Array[int] # array of phrase IDs


class SongPhraseIteration:
	var time: float
	var phrase_id: int # index in the phrases array
	var variation
	var hero_levels: Array[HeroLevel]
	
	class HeroLevel:
		var difficulty: int
		var hero: int


class SongChordTemplate:
	var display_name: String
	var chord_name: String
	var fret_0: int
	var fret_1: int
	var fret_2: int
	var fret_3: int
	var fret_4: int
	var fret_5: int
	var finger_0: int
	var finger_1: int
	var finger_2: int
	var finger_3: int
	var finger_4: int
	var finger_5: int


class SongEbeat:
	var time: float
	var measure: int


class SongTone:
	var time: float
	var id: int
	var name: String


class SongSection:
	var name: String
	var number: int
	var start_time: float


class SongEvent:
	var time: float
	var code: String


class SongTranscriptionTrack:
	var difficulty: int
	# I suspect the below are the same types as in the song data
	var notes: Array # TODO: xml has none of these, figure out what it is
	var chords: Array # TODO: xml has none of these, figure out what it is
	var anchors: Array # TODO: xml has none of these, figure out what it is
	var hand_shapes: Array # TODO: xml has none of these, figure out what it is
	var fret_hand_mutes: Array # TODO: xml has none of these, figure out what it is


class SongLevel:
	var difficulty: int
	var notes: Array[SongLevelNote]
	var chords: Array[SongLevelChord]
	var anchors: Array[SongLevelAnchor]
	var hand_shapes: Array[SongLevelHandShape]
	
	
	class SongLevelNote:
		var time: float
		var link_next: bool
		var accent: bool
		var bend: bool
		var fret: int
		var hammer_on: bool
		var harmonic: bool
		var hopo: bool
		var ignore: bool
		var left_hand: int
		var mute: bool
		var palm_mute: bool
		var pluck: int
		var pull_off: bool
		var slap: int
		var slide_to: int
		var string: int
		var sustain: float
		var tremolo: bool
		var harmonic_pinch: bool
		var pick_direction: bool
		var right_hand: int
		var slide_unpitch_to: int
		var tap: bool
		var vibrato: bool
	
	
	class SongLevelChord:
		var time: float
		var link_next: bool
		var accent: bool
		var chord_id: int
		var fret_hand_mute: bool
		var high_density: bool
		var ignore: bool
		var palm_mute: bool
		var hopo: bool
		var strum: String # Guessing this is actually an enum containing strum directions
		var chord_notes: Array[SongLevelChordNote]
		
		# Below looks idential to basic note
		class SongLevelChordNote:
			var time: float
			var link_next: bool
			var accent: bool
			var bend: bool
			var fret: bool
			var hammer_on: bool
			var harmonic: bool
			var hopo: bool
			var ignore: bool
			var left_hand: int
			var mute: bool
			var palm_mute: bool
			var pluck: int
			var pull_off: bool
			var slap: int
			var slide_to: int
			var string: int
			var sustain: float
			var tremolo: bool
			var harmonic_pinch: bool
			var pick_direction: bool
			var right_hand: int
			var slide_unpitch_to: int
			var tap: bool
			var vibrato: bool
	
	
	class SongLevelAnchor:
		var time: float
		var fret: int
		var width: int
	
	
	class SongLevelHandShape:
		var chord_id: int
		var end_time: float
		var start_time: float

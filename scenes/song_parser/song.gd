class_name Song


var version: int
var title: String
var arrangement: String
var part: int
var offset: float
var cent_offset: float
var song_length: float
var song_name_sort: String
var start_beat: float
var average_tempo: float
var tuning: Dictionary
var capo: int
var artist_name: String
var artist_name_sort: String
var album_name: String
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
var ebeats: Array[SongEBeat]
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


class SongEBeat:
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
		var mote: bool
		var palm_mute: bool
		var pluck: int
		var pull_off: bool
		var slap: int
		var slide_to: int
		var string: int
		var sustain: bool
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
			var sustain: bool
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

extends InputInstrument

var inputs: Array[int]
var started_notes: Array [int]

var threshold := -40.0
var volume_range: float = 0.5
var pitch_accuracy = 0.025
var last_peak: Vector3
var last_raw_peaks: PackedVector2Array = []
var last_pure_raw_peaks: PackedVector2Array = []
# if the volume of the same note changes by this much in a single frame
# it means that the note was triggered again.
var volume_spike_ratio := 1.5


# Defines volume hysteresis. It's supposed to work for each note separately.
# Currently we have only 1 note at a time.
var volume_start_threshold := 0.15
var volume_end_threshold := 0.05

# real instruments will produce noise as well.
# so we search amongst peaks to find the right frequency.
# TODO : Currently volume of all frequencies has the same weight for searching.
# 	however it's possible that lower frequencies should get lower weights.
# 	even a gradual logarithmic based decline of weights should suffice.

# notes that have a volume lower than 0.8 times the loudest volume will be filtered.
var clarity_filter_ratio := 0.8
var total_clarity_filter_ratio := 0.66
var chromatic_filter_depth := 12*2

enum DETECTION_METHOD {
	PIANO,
	STRING,
}

enum START_STATE {
	NONE,
	STARTING,
	STARTED,
	STOPPING,
}

const fadj_lfactor := 1.0/22000.0
# this is for adjustability of the multiplier.


# note transition timer
# after x seconds of presistance, the trigger will happen.
var note_transition_trigger := 0.05

# key : value = chromatic_index : { frequency, volume, duration, start_state }
var current_peaks := {}

func _ready():
	super._ready()
	
	deactivated.connect(_on_deactivated)
	GAudioServerManager.new_frame_processed.connect(_on_new_frame_processed)


# the current algorithm does not support note trails or chords.
# this means multiple notes at the same time cannot be triggered.
# note_ended will also be incorrect.
var time_passed = 0.0
var start_volume := 0.0
var last_total_energy := 0.0
#var accum_delta := 0.0
var last_started_note_chromatic := -1
var last_started_note_timstamp := 0.0
var min_retrigger_interval := 0.1


func _on_new_frame_processed(delta, last_pure_raw_peaks):
	time_passed += delta
	var total_magnitude: float = GAudioServerManager.get_volume(20.0, 22000.0)
	var total_energy: float = clamp((60.0 + linear_to_db(total_magnitude)) / 60.0, 0, 1)
	
	var min_frequency: float
	var max_frequency: float
	var volume: float
	
	var previous_inputs = inputs.duplicate()
	inputs = []
	var prev_last_raw_peak := last_raw_peaks
	last_raw_peaks = last_pure_raw_peaks
	var peaks := adjust_and_filter_peaks(last_raw_peaks)
	var prev_peaks := current_peaks.duplicate(true)
	
	var peak_chromatics: PackedInt32Array = []
	for peak in peaks:
		peak_chromatics.append(int(peak.z))
	
	var cp_keys = current_peaks.keys()
	for peak_chr in cp_keys:
		# TODO : replace with binary search. maybe even resue peak_frequencies.
		var peak = current_peaks[peak_chr]
		if not (peak_chr in peak_chromatics):
			if peak["start_state"] == START_STATE.STARTED:
				# the note will be removed in the next audio frame.
#				end_note(peak_chr)
				current_peaks[peak_chr]["start_state"] = START_STATE.STOPPING
				current_peaks[peak_chr]["volume"] = peak["volume"]*0.5
				current_peaks[peak_chr]["duration"] += delta
			else:
				current_peaks.erase(peak_chr)
		elif peak["start_state"] == START_STATE.STOPPING:
			peak["start_state"] = START_STATE.STARTED
			
	var pc = current_peaks.duplicate(true)
	for peak in peaks:
		var prev_volume := 0.0
		var current_volume := 0.0
		var prev_duration := 0.0
		var current_duration := 0.0
		var chromatic := int(peak.z)
		var retrigger := false
		if current_peaks.has(chromatic):
			var start_state: START_STATE = current_peaks[chromatic]["start_state"]
			var prev_peak = current_peaks[chromatic]
			prev_volume = prev_peak["volume"]
			current_volume = peak.y
			current_peaks[chromatic]["volume"] = current_volume
			current_peaks[chromatic]["frequency"] = peak.x
			prev_duration = current_peaks[chromatic]["duration"]
			var next_duration = prev_duration + delta
			current_peaks[chromatic]["duration"] = next_duration
			if start_state == START_STATE.STARTING and next_duration > note_transition_trigger:
				current_peaks[chromatic]["start_state"] = START_STATE.STARTED
				start_note(chromatic)
				print("Microphone input note %s(%s, %s Hz) started at frame :" % [NoteFrequency.CHROMATIC_NAMES[peak.z], peak.z, str(peak.x)], Engine.get_frames_drawn(), ", clearity =", current_volume, ", time =", time_passed)
			elif current_volume > prev_volume*4.2:
				print("Microphone input. note %d retrigger detected. spike ratio : %s" % [chromatic, str(current_volume/prev_volume)])
				retrigger = true
		else:
			retrigger = true
			
			# start notes that have been sustained for long enough.
		if retrigger:
			# new peak
			current_volume = peak.y
			if current_volume > volume_start_threshold:
				current_peaks[chromatic] = {
					"frequency": peak.x,
					"volume": current_volume,
					"duration": 0,
					"start_state": START_STATE.NONE,
				}
				var fmag =  GAudioServerManager.get_volume(peak.x*0.3, peak.x*3.0)
				var ferg = clamp((60.0 + linear_to_db(fmag)) / 60.0, 0, 1)
				var mvol := 0.0
				for peak_chr in current_peaks:
					var pvol = current_peaks[peak_chr]["volume"]
					if pvol > mvol:
						mvol = pvol
				if (total_energy > last_total_energy or peak.y > 0.95*ferg) and peak.y > mvol*0.9 :
#					if last_started_note_chromatic != chromatic or last_started_note_timstamp >= min_retrigger_interval:
					current_peaks[chromatic]["start_state"] = START_STATE.STARTING
	
	for peak_chr in current_peaks.keys():
		var start_state: START_STATE = current_peaks[peak_chr]["start_state"]
		if start_state != START_STATE.STARTING:
			continue
		var current_volume: float = current_peaks[peak_chr]["volume"]
		if current_volume < volume_start_threshold:
			current_peaks[peak_chr]["start_state"] = START_STATE.NONE
		else:
			var prev_peak = current_peaks.get(peak_chr - 12)
			if prev_peak:
				var pp_volume = prev_peak["volume"]
				if pp_volume > 0.3*current_volume:
					current_peaks.erase(peak_chr)
	
	last_total_energy = total_energy


func weight_volume(frequency, volume) -> float:
	return volume*pow(frequency, 0.1)


func get_volume(freq) -> float:
	return GAudioServerManager.spectrum.get_magnitude_for_frequency_range(100, 100000).length()


func end_note(chromatic) -> void:
	note_ended.emit(NoteFrequency.CHROMATIC[chromatic])


func start_note(chromatic) -> void:
	last_started_note_chromatic = chromatic
	last_started_note_timstamp = time_passed
	note_started.emit(NoteFrequency.CHROMATIC[chromatic])


func adjust_and_filter_peaks(peaks) -> PackedVector3Array:
	if peaks.is_empty():
		return []
	# TODO : make these calculations independent of audio server.
	var total_magnitude: float = GAudioServerManager.get_volume(0.0, 22000.0)
	var total_energy: float = clamp((60.0 + linear_to_db(total_magnitude)) / 60.0, 0, 1)
	
	var filter_peak := volume_end_threshold
	var ret: PackedVector3Array = []
	var chromatic_index := NoteFrequency.CHROMATIC.size() - 1
	var first_peak = peaks[0]
	while(chromatic_index > 1):
		if NoteFrequency.CHROMATIC[chromatic_index - 1] > first_peak.x:
			chromatic_index -= 1
		else:
			break
	var chromatic_end = max(0, chromatic_index - chromatic_filter_depth)
	# peaks are ordered. highest frequency comes first.
	# chromatics are ordered in the opposite way.
	# TODO : optimize this loop.
	var last_added_chromatic := -1
	for peak in peaks:
		if peak.y < filter_peak:
			continue
		# adjust the frequency
		peak.x *= 0.99
		# chromatic
		var chromatic := 0.0
		while(chromatic_index > 1):
			if NoteFrequency.CHROMATIC[chromatic_index - 1] > peak.x:
				chromatic_index -= 1
			else:
				break
		if chromatic_end > chromatic_index:
			break
		var lchrome = NoteFrequency.CHROMATIC[chromatic_index -1]
		var rchrome = NoteFrequency.CHROMATIC[chromatic_index]

		var ldis = abs(lchrome - peak.x)/lchrome
		var rdis = abs(rchrome - peak.x)/rchrome
		if rdis > pitch_accuracy and ldis > pitch_accuracy:
			continue
		
		if ldis < rdis:
			chromatic = chromatic_index - 1
		else:
			chromatic = chromatic_index
		if chromatic == last_added_chromatic:
			ret[ret.size() - 1].y += peak.y
		ret.push_back(Vector3(peak.x, peak.y, chromatic))
		last_added_chromatic = chromatic

	return ret


func get_inputs()->Array:
	return inputs


func _on_deactivated() -> void:
	current_peaks.clear()

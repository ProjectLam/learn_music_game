extends InputInstrument

signal new_dominant_peak_detected(peak: Vector3)

enum DetectionMode {
	CLUSTER,
	DOMINANT_PEAK,
}

var detection_mode := DetectionMode.DOMINANT_PEAK

var inputs: Array[int]
var started_notes: Array [int]

var threshold := -40.0
var volume_range: float = 0.5
var pitch_accuracy = 0.035
var last_peak: Vector3
var last_raw_peaks: PackedVector2Array = []
var last_adjusted_peaks: PackedVector3Array = []
var last_pure_raw_peaks: PackedVector2Array = []
var dominant_peak_trigger_duration := 0.075
# if the volume of the same note changes by this much in a single frame
# it means that the note was triggered again.
var volume_spike_ratio := 1.02


# Defines volume hysteresis. It's supposed to work for each note separately.
# Currently we have only 1 note at a time.
var volume_start_threshold := 0.15
var volume_end_threshold := 0.05
var clarity_threshold := -1.0:
	set = set_clarity_threshold

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
var current_peaks: Dictionary = {}
var old_peaks: Dictionary = {}
var old_peaks_2: Dictionary = {}
var last_volume: float = 0.0

func _ready():
	super._ready()
	
	deactivated.connect(_on_deactivated)
	GAudioServerManager.new_frame_processed.connect(_on_new_frame_processed)
	
	var mic_profile = PlayerVariables.microphone_input_profiles.get(PlayerVariables.selected_input_device)
	if mic_profile:
		load_input_profile(mic_profile)

	detection_delay = 1.0/44.0
	
	

# the current algorithm does not support note trails or chords.
# this means multiple notes at the same time cannot be triggered.
# note_ended will also be incorrect.
var time_passed = 0.0
var start_volume := 0.0
var last_total_energy := 0.0
#var accum_delta := 0.0
var last_started_note_chromatic := -1
var last_started_note_timstamp := 0.0
var min_retrigger_interval := 0.07


func _on_new_frame_processed(delta, last_pure_raw_peaks):
	time_passed += delta
	if not is_active:
		return
	var total_magnitude: float = GAudioServerManager.get_total_record_volume()#GAudioServerManager.get_volume(0.0, 22000.0)
#	var total_energy: float = clamp((60.0 + linear_to_db(total_magnitude)) / 60.0, 0, 1)
	var total_energy: float = clamp((60.0 + total_magnitude) / 60.0, 0, 1)
	last_volume = total_energy
	var min_frequency: float
	var max_frequency: float
	var volume: float

	var previous_inputs = inputs.duplicate()
	inputs = []
	var prev_last_raw_peak := last_raw_peaks
	last_raw_peaks = last_pure_raw_peaks
	var peaks := adjust_and_filter_peaks(last_raw_peaks)
	last_adjusted_peaks = peaks
	old_peaks_2 = old_peaks
	old_peaks = current_peaks.duplicate(true)
	
	var dominant_peak: Vector3 = find_dominant_peak(last_raw_peaks)
	
	var peak_chromatics: PackedInt32Array = []
	for peak in peaks:
		peak_chromatics.append(int(peak.z))
	
	var cp_keys = current_peaks.keys()
	
	var current_ended_notes: PackedInt32Array = []
	var current_started_notes: PackedInt32Array = []
	
	match(detection_mode):
		DetectionMode.CLUSTER:
			for peak_chr in cp_keys:
				var peak = current_peaks[peak_chr]
				if not (peak_chr in peak_chromatics):
					current_peaks.erase(peak_chr)
					current_ended_notes.append(peak_chr)
			
			for peak in peaks:
				var chromatic := int(peak.z)
				var current_frequency: float = peak.x
				var current_volume := peak.y
				var current_duration := 0.0
				var prev_volume := 0.0
				var prev_duration := 0.0
				var prev_volume_2 := 0.0
				var prev_duration_2 := 0.0
				var trigger := true
				
				if current_peaks.has(chromatic):
					prev_volume = current_peaks[chromatic]["volume"]
					prev_duration = current_peaks[chromatic]["duration"]
					current_duration = prev_duration + delta
					trigger = false
				
				if old_peaks_2.has(chromatic):
					prev_volume_2 = old_peaks_2[chromatic]["volume"]
					prev_duration_2 = old_peaks_2[chromatic]["volume"]
				
		#		current_volume = 0.5*(prev_volume + current_volume)
				
		#		if current_volume < prev_volume and prev_volume_2 < prev_volume and prev_duration > min_retrigger_interval:
		#			current_duration = delta
		#			trigger = true
					
				current_peaks[chromatic] = {
					"volume": current_volume,
					"duration": current_duration,
					"frequency": current_frequency
				}
				
				if trigger:
					current_started_notes.append(chromatic)
		DetectionMode.DOMINANT_PEAK:
			var chromatic := int(dominant_peak.z)
			var current_volume := dominant_peak.y
			var current_duration: float = delta
			var current_frequency := dominant_peak.x
			var prev_duration: float = 0.0
			var trigger := true
			if current_peaks.has(chromatic):
				if current_volume > volume_end_threshold:
					prev_duration = current_peaks[chromatic]["duration"]
					current_duration = prev_duration + delta
					current_peaks[chromatic] = {
						"volume": current_volume,
						"duration": current_duration,
						"frequency": current_frequency,
						"started": current_peaks[chromatic]["started"]
					}
			else:
				for chormatic in current_peaks:
					current_ended_notes.append(chromatic)
				current_peaks.clear()
				
				
				if current_volume > volume_start_threshold:
					current_peaks[chromatic] = {
						"volume": current_volume,
						"duration": current_duration,
						"frequency": current_frequency,
						"started": false,
					}
				else:
					trigger = false
			
			if prev_duration < dominant_peak_trigger_duration and current_duration > dominant_peak_trigger_duration:
				if trigger:
					current_started_notes.append(chromatic)
				
#			start_note(chromatic)
	# signal emissions are done at the end so that the updated states are accessible to connected methods.
	for enote in current_ended_notes:
		end_note(enote)
	
	for snote in current_started_notes:
		current_peaks[snote]["started"] = true
		start_note(snote) 
	
	
	if dominant_peak.y > volume_start_threshold:
		print("Dominant peak with raw peaks :", dominant_peak, ":   ", current_peaks)
		new_dominant_peak_detected.emit(dominant_peak)


func weight_volume(frequency, volume) -> float:
	return volume*pow(frequency, 0.1)


func get_volume(freq) -> float:
	return GAudioServerManager.spectrum.get_magnitude_for_frequency_range(100, 100000).length()


func end_note(chromatic) -> void:
	if chromatic > NoteFrequency.CHROMATIC.size() - 1:
		return
	note_ended.emit(NoteFrequency.CHROMATIC[chromatic])
#	match(mode):
#		Modes.KEYBOARD:
#		Modes.FRET:
#			var string_fret = chromatic_index_to_fret(chromatic)
#			fret_ended.emit(string_fret.x, string_fret.y)


func start_note(chromatic) -> void:
	last_started_note_chromatic = chromatic
	last_started_note_timstamp = time_passed
	note_started.emit(NoteFrequency.CHROMATIC[chromatic])
#	match(mode):
#		Modes.KEYBOARD:
#		Modes.FRET:
#			var string_fret = chromatic_index_to_fret(chromatic)
#			fret_started.emit(string_fret.x, string_fret.y)


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
		var volume : float = peak.y#;GAudioServerManager.get_volume(peak.x*0.975, peak.x*1.025)
#		volume = (60.0 + linear_to_db(volume)) / 60.0
		if volume < filter_peak:
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
			ret[ret.size() - 1].y += volume
		ret.push_back(Vector3(peak.x, volume, chromatic))
		last_added_chromatic = chromatic
	
	return remove_lower_harmonics(ret)
#	return ret


func get_inputs()->Array:
	return inputs


func _on_deactivated() -> void:
	current_peaks.clear()


func get_device_names() -> PackedStringArray:
	return [
		AudioServer.input_device
	]


func generate_input_profile() -> Dictionary:
	return {
		"volume_end_threshold": volume_end_threshold,
		"volume_start_threshold": volume_start_threshold,
		"clarity_threshold": clarity_threshold,
	}


func load_input_profile(prof: Dictionary) -> void:
	reset_input_profile()
	
	var vet = prof.get("volume_end_threshold")
	var vst = prof.get("volume_start_threshold")
	var vct = prof.get("clarity_threshold")
	
	if vet is float:
		volume_end_threshold = vet
	
	if vst is float:
		volume_start_threshold = vst
	
	if vct:
		clarity_threshold = vct


func reset_input_profile() -> void:
	volume_start_threshold = 0.15
	volume_end_threshold = 0.05
	clarity_threshold = 0.76


func save_volume_profile():
	PlayerVariables.microphone_input_profiles[PlayerVariables.selected_input_device] = generate_input_profile()
	PlayerVariables.save()


func reload_volume_profile():
	var prof = PlayerVariables.microphone_input_profiles.get(PlayerVariables.selected_input_device)


func set_clarity_threshold(value: float) -> void:
	if clarity_threshold != value:
		clarity_threshold = value
		GAudioServerManager.set_record_peaks_clarity(value)


func remove_lower_harmonics(peaks: PackedVector3Array) -> PackedVector3Array:
	var chromatics: PackedInt32Array = []
	var ret: PackedVector3Array = []
	for peak in peaks:
		if not chromatics.has(int(peak.z) + 12):
			chromatics.append(int(peak.z))
			ret.append(peak)
	
	return ret


func find_dominant_peak(peaks: PackedVector2Array) -> Vector3:
	var mindex := -1
	var dp: Vector2
	var chromatic := -1
	
	var min_freq := 80.0#0.0 if peaks.size() == 0 else peaks[0].x*0.45
	
	for index in peaks.size():
		var peak := peaks[index]
		if peak.x < min_freq:
			break
		
		if peak.y < volume_start_threshold:
			continue
		if peak.y > dp.y:
			dp = peak
			mindex = index
		else:
			break
	
	var index = NoteFrequency.CHROMATIC.bsearch(dp.x, false)
	if index == 0:
		pass
	elif index < NoteFrequency.CHROMATIC.size() - 2:
		var before = NoteFrequency.CHROMATIC[index]
		var after = NoteFrequency.CHROMATIC[index+1]
		var before_dis = abs(before-dp.x)
		var after_dis = abs(after-dp.x)
		
		if before_dis < after_dis:
			chromatic = index
		else:
			chromatic = index + 1
	else:
		chromatic = NoteFrequency.CHROMATIC[NoteFrequency.CHROMATIC.size() - 1]
	
	return Vector3(dp.x, dp.y, chromatic)

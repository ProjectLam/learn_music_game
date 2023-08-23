extends Node

signal new_note_frame_processed(delta: float, data)
signal new_chroma_frame_processed(delta: float, deta, max_volume)

const MIN_DB = 60

var mix_rate := 0
var analyze_bus: int
var record_peaks_effect: int = 0
var record_spectrum_effect: int = 1
var bus_layout: AudioBusLayout = preload("res://default_bus_layout.tres")
var reset_audio_bus := false
var pitch_accuracy = 0.025
var pitch_analyzer_fft_size := 0
var pitch_analyzer_delta := 0.0

# for repeatitive not ciritical tasks, locking MIGHT ruin things.
# disabling locking might result in no change.
# locking is still done by default for safety.
var lock_audio_server := true


func _ready():
	AudioServer.lock()
	analyze_bus = AudioServer.get_bus_index("NoteDetection")
	pitch_analyzer_fft_size = 256 << AudioServer.get_bus_effect(analyze_bus, record_peaks_effect).get("fft_size")
	var mix_rate = AudioServer.get_mix_rate()
	pitch_analyzer_delta = float(pitch_analyzer_fft_size) / mix_rate
	AudioServer.unlock()
	
	set_record_peaks_clarity(0.60)
	get_pitch_analyzer().connect("new_frame_processed", _on_new_pa_frame_processed)
	get_spectrum_analyzer().connect("new_frame_processed", _on_new_chroma_frame_processed)


func _process(delta):
	if reset_audio_bus:
		call_deferred("_reload_audio_bus")
		reset_audio_bus = false


# lock AudioServer before calling this
func get_pitch_analyzer() -> AudioEffectPitchAnalyzerInstance:
	return AudioServer.get_bus_effect_instance(analyze_bus,record_peaks_effect)


func get_spectrum_analyzer():
	return AudioServer.get_bus_effect_instance(analyze_bus, record_spectrum_effect)


func get_record_peaks() -> PackedVector2Array:
	if(lock_audio_server):
		AudioServer.lock()
	var arr: PackedVector2Array = []
	var spectrum = get_pitch_analyzer()
	if(spectrum):
		arr = spectrum.get_peaks()
	if(lock_audio_server):
		AudioServer.unlock()
	return arr


func get_volume(start_frequency, end_frequency) -> float:
	var spectrum = get_spectrum_analyzer()
	return spectrum.get_magnitude_for_frequency_range(start_frequency, end_frequency).length()


func get_total_record_volume() -> float:
#	var spectrum = get_spectrum_analyzer()
#	var ranges: Array[Vector2i] = [
#		Vector2i(31.5,63),
#		Vector2i(63,125),
#		Vector2i(250,500),
#		Vector2i(500,1000),
#		Vector2i(1000,2000),
#		Vector2i(2000,4000),
#		Vector2i(8000,16000)
#	]
#
#	var sum := 0.0
#
#	for range in ranges:
#		sum += spectrum.get_magnitude_for_frequency_range(range.x, range.y).length()
#
#	return sum
#	var f1 = 
#
	return 0.5*((AudioServer.get_bus_peak_volume_left_db(2,0)) + AudioServer.get_bus_peak_volume_right_db(2,0))


func set_record_peaks_clarity(clarity : float = 0.05):
	# Note : there is a cpoule of ways to do this
	var peffect = bus_layout.get("bus/%d/effect/%d/effect" % 
			[analyze_bus, record_peaks_effect])
	peffect.set("clarity_threshold", clarity)
	# forces to recreate the instances with the new settings.
	# not the most efficient way but the most generic way.
	reset_audio_bus = true


func _reload_audio_bus():
	AudioServer.set_bus_layout(bus_layout)
	get_pitch_analyzer().connect("new_frame_processed", _on_new_pa_frame_processed)
	get_spectrum_analyzer().connect("new_frame_processed", _on_new_chroma_frame_processed)


func mute_analyze(muted: bool):
	bus_layout.set("bus/%d/mute" % [analyze_bus], muted)
	reset_audio_bus = true
#	AudioServer.set_bus_mute(analyze_bus, muted)


func _set_volumes(input_peaks: PackedVector2Array) -> PackedVector2Array:
	var ret = input_peaks.duplicate()
	for index in input_peaks.size():
		var peak := input_peaks[index]
		var frequency: float = peak.x
		var magnitude: float = get_volume(frequency*(1 - 1.0*pitch_accuracy), frequency*(1 + 1.0*pitch_accuracy))
		var energy: float = clamp((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		ret[index].y = energy
	
	return ret


func _on_new_pa_frame_processed(data):
	new_note_frame_processed.emit(pitch_analyzer_delta, _set_volumes(data))


func _on_new_chroma_frame_processed(data):
	const handle_strength := 0.5
#	var cdata := {}
#	var bf2: Vector2
#	var bf: Vector2
#	var af: Vector2
#	var af2: Vector2
	const freq_factor := 246.0
	const freq_factor_base := 1.2
#	var bfset := false
	var chroma_volumes: PackedFloat32Array = []
	chroma_volumes.resize(NoteFrequency.CHROMATIC.size())
	var chroma_count = chroma_volumes.size()
	var next_chroma_index := 24
	var next_chroma_freq = NoteFrequency.CHROMATIC[next_chroma_index]
	var fstep: float = 22000.0/data.size()
	var invfstep := 1.0/fstep
	var volumes: PackedFloat32Array = []
	volumes.resize(data.size())
	var maxvol := 40.0
	var total_vol := 0.0
	for index in data.size():
		var volume: float = data[index].length()
		volumes[index] = volume
	
	
	for index in range(2, data.size()):
		var vec: Vector2 = data[index]
		var freq := fstep*index
		for chroma_index in range(next_chroma_index, chroma_count):
			if next_chroma_freq < freq:
				var afreq := (index - 2)*fstep
				var avol := volumes[index-2]
				var bfreq := (index - 1)*fstep
				var bvol := volumes[index-1]
				var cfreq := freq
				var cvol := volumes[index]
				var dfreq := (index + 1)*fstep
				var dvol := volumes[index+1]
				
				var control1 := bvol + handle_strength*(bvol - avol)
				var control2 := cvol + handle_strength*(cvol - dvol)
				
				var t = (next_chroma_freq - bfreq)*invfstep
#				t = 0
				var intvalue := bezier_interpolate(bvol, control1, control2, cvol, t)
				intvalue *= next_chroma_freq/freq_factor
				
				
				total_vol += max(intvalue, 0)
				if intvalue > maxvol:
					maxvol = max(intvalue, 0)
				
				chroma_volumes[next_chroma_index] = intvalue
				
				next_chroma_index += 1
				if next_chroma_index != chroma_count:
					next_chroma_freq = NoteFrequency.CHROMATIC[next_chroma_index]
				else:
					break
			else:
				break
	
	total_vol = total_vol/chroma_volumes.size()
	var vol_norm := 1.0/total_vol
	for index in chroma_volumes.size():
		chroma_volumes[index] *= vol_norm
	
	# octave filtering.
	var cvdup: PackedFloat32Array = chroma_volumes.duplicate()
#	for index in chroma_volumes.size() - 7:
#		chroma_volumes[index] += -cvdup[index + 7]*0.9# - cvdup[index + 1]*0.9
			
	cvdup = chroma_volumes.duplicate()
	
	var additions: PackedFloat32Array = []
	additions.resize(chroma_volumes.size())

	for index in chroma_volumes.size():
		for index2 in range(index+12, chroma_volumes.size(), 12):
			additions[index2] += -cvdup[index]*3.0

	for index in chroma_volumes.size():
		for index2 in range(index+19, chroma_volumes.size(), 12):
			additions[index2] += -cvdup[index]*3.0

	for index in range(19, chroma_volumes.size()):
		# rule out 3x overtune.
		additions[index] += -cvdup[index-19]*3.0


	for index in range(28, chroma_volumes.size()):
		# rule out 5x overtune.
		additions[index] += -cvdup[index-28]*1.0
	
	var mchroma := 0.5
	for index in additions.size():
		var value := max(chroma_volumes[index] + additions[index], 0)
		chroma_volumes[index] = value
		if value > mchroma:
			mchroma = value
	
	var mchroma_norm := 1.0 / mchroma
	for index in chroma_volumes.size():
		chroma_volumes[index] *= mchroma_norm
	
	var tv := []
	var chroma_volume_derivatives: PackedFloat32Array = []
	chroma_volume_derivatives.resize(chroma_volumes.size())
	for index in range(1, chroma_volumes.size() -1):
		var before := chroma_volumes[index -1]
		var at := chroma_volumes[index]
		var after := chroma_volumes[index+1]
		var maxv := max(before,after)
		chroma_volume_derivatives[index] = at - maxv
	
	
	new_chroma_frame_processed.emit(pitch_analyzer_delta, chroma_volumes, clamp(linear_to_db(mchroma*total_vol)/MIN_DB, 0, 2.0))


func set_input_device(dev_name: String) -> void:
	if AudioServer.get_input_device_list().has(dev_name):
		AudioServer.input_device = dev_name
		PlayerVariables.selected_input_device = dev_name
		PlayerVariables.save()

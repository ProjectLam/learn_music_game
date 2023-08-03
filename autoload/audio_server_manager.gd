extends Node

signal new_frame_processed(delta, data)

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


func mute_analyze(muted: bool):
	bus_layout.set("bus/%d/mute" % [analyze_bus], muted)
	reset_audio_bus = true
#	AudioServer.set_bus_mute(analyze_bus, muted)


func _set_volumes(input_peaks: PackedVector2Array) -> PackedVector2Array:
	const MIN_DB = 60
	var ret = input_peaks.duplicate()
	for index in input_peaks.size():
		var peak := input_peaks[index]
		var frequency: float = peak.x
		var magnitude: float = get_volume(frequency*(1 - 3.0*pitch_accuracy), frequency*(1 + 3.0*pitch_accuracy))
		var energy: float = clamp((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		ret[index].y = energy
	
	return ret


func _on_new_pa_frame_processed(data):
	new_frame_processed.emit(pitch_analyzer_delta, _set_volumes(data))


func set_input_device(dev_name: String) -> void:
	if AudioServer.get_input_device_list().has(dev_name):
		AudioServer.input_device = dev_name
		PlayerVariables.selected_input_device = dev_name
		PlayerVariables.save()

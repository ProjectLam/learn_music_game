extends InputInstrument


var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance
var inputs: Array


func _ready():
	spectrum_analyzer = AudioServer.get_bus_effect_instance(
		AudioServer.get_bus_index("Input"),
		1
		) as AudioEffectSpectrumAnalyzerInstance


func _process(delta):
	var min_frequency: float
	var max_frequency: float
	var volume: float
	
	var threshold = -40
	var pitch_accuracy: float = 0.5
	
	var previous_inputs = inputs.duplicate()
	inputs = []
	for note in NoteFrequency.CHROMATIC:
		min_frequency = 0.5 * note * pow(2, (23 + pitch_accuracy)/24.0)
		max_frequency = note * pow(2, (1 - pitch_accuracy)/24.0)
		volume = linear_to_db(spectrum_analyzer.get_magnitude_for_frequency_range(min_frequency, max_frequency).x)
		if volume >= threshold:
			inputs.append(note)
	
	for note in previous_inputs:
		if not note in inputs:
			note_ended.emit(note)
	
	for note in inputs:
		if not note in previous_inputs:
			note_started.emit(note)


func get_inputs()->Array:
	return inputs

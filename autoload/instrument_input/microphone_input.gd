extends InputInstrument


var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance
var inputs: Array

var threshold := -40.0
var pitch_accuracy: float = 0.1


func _ready():
	spectrum_analyzer = AudioServer.get_bus_effect_instance(
		AudioServer.get_bus_index("Input"),
		1
		) as AudioEffectSpectrumAnalyzerInstance


func _process(delta):
	var min_frequency: float
	var max_frequency: float
	var volume: float
	
	var previous_inputs = inputs.duplicate()
	inputs = []
	for note in NoteFrequency.CHROMATIC:
		min_frequency = note * pow(2, -pitch_accuracy/12)
		max_frequency = note * pow(2, pitch_accuracy/12)
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

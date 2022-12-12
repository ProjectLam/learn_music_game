extends Control


enum TuningMode {
	CHROMATIC,
	GUITAR,
	PHIN,
}

@export var tuning_mode: TuningMode
@export var max_needle_angle = 70.0

@onready var needle = $%"Needle"


func _process(delta):
	var sin_value = 8 * (sin(0.0001 * Time.get_ticks_msec()) + 1) * 0.5
	var frequency = 27.5 * pow(2, sin_value)
	set_input_frequency(frequency)


func set_input_frequency(new_frequency: float):
	var nearest_frequency_data = _get_nearest_target_frequency(new_frequency)
	$Label.text = nearest_frequency_data.note_name
	
	var target: float = nearest_frequency_data.frequency
	var min_frequency: float = 0.5 * target * pow(2.0, 11.5/12.0)
	var max_frequency: float = target * pow(2, 0.5/12.0)
	
	var deviation = inverse_lerp(min_frequency, max_frequency, new_frequency)
	deviation = clamp(deviation, 0.0, 1.0)
	
	needle.rotation = deg_to_rad(lerp(-max_needle_angle, max_needle_angle, deviation))


func _get_nearest_target_frequency(frequency: float):
	var frequencies: Array
	var note_names: Array
	
	match tuning_mode:
		TuningMode.CHROMATIC:
			frequencies = NoteFrequency.CHROMATIC.duplicate()
			note_names = NoteFrequency.CHROMATIC_NAMES.duplicate()
		TuningMode.GUITAR:
			frequencies = [
				NoteFrequency.E2,
				NoteFrequency.A2,
				NoteFrequency.D3,
				NoteFrequency.G3,
				NoteFrequency.B3,
				NoteFrequency.E4
				]
			note_names = ["E2", "A2", "D3", "G3", "B3", "E4"]
		TuningMode.PHIN:
			frequencies = [
				NoteFrequency.E3,
				NoteFrequency.A3,
				NoteFrequency.E4
			]
			note_names = ["E3", "A3", "E4"]
	
	var target_index: int = 0
	for i in frequencies.size():
		if abs(frequencies[i] - frequency) < abs(frequencies[target_index] - frequency):
			target_index = i
	
	return {
		frequency = frequencies[target_index],
		note_name = note_names[target_index]
	}
